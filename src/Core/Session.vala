public class Starfish.Core.Session : Object {

    private string _name;
    private Uri[] _history;
    private int _history_index;
    private SessionManager manager { get; set; }

    public bool loading { get; set; default = false; }
    public string name { get { return _name; } }
    public Gee.List<Uri> history {
        owned get { return new Gee.ArrayList<Uri>.wrap (_history); }
    }

    public int history_index { get { return _history_index; } }
    public Uri current_uri {
        get { return _history[_history_index]; }
        private set { _history[_history_index] = value; }
    }

    public Session (
        string name,
        Uri[] history,
        int history_index,
        SessionManager manager
    ) {
        _name = name;
        _history = history;
        _history_index = history_index;
        this.manager = manager;
    }

    public signal void response_received (Response response);
    public signal void cancel_loading ();

    public void init () {
        lock (loading) {
            if (loading) {
                return;
            } else {
                loading = true;
            }

            var starting_uri = current_uri;
            manager.client.load.begin (starting_uri, null, (obj, res) => {
                var response = manager.client.load.end (res);
                response_received (response);
            });
        }
    }

    public void navigate_back () {
        if (_history_index <= 0) {
            return;
        }

        lock (loading) {
            if (loading) {
                return;
            } else {
                loading = true;
            }

            var uri = _history[_history_index - 1];
            manager.client.load.begin (uri, null, (obj, res) => {
                var response = manager.client.load.end (res);
                var loaded_uri = response.uri;
                _history_index--;
                if (current_uri.to_string() != loaded_uri.to_string ()) {
                    _history = _history[0:_history_index];
                    current_uri = loaded_uri;
                }
                manager.save (this);
                response_received (response);
            });
        }
    }

    public void navigate_forward () {
        if (_history_index >= _history.length - 1) {
            return;
        }

        lock (loading) {
            if (loading) {
                return;
            } else {
                loading = true;
            }

            var uri = _history[_history_index + 1];
            manager.client.load.begin (uri, null, (obj, res) => {
                var response = manager.client.load.end (res);
                var loaded_uri = response.uri;
                _history_index++;
                manager.save (this);
                if (current_uri.to_string() != loaded_uri.to_string ()) {
                    _history = _history[0:_history_index];
                    current_uri = loaded_uri;
                }
                manager.save (this);
                response_received (response);
            });
        }
    }

    public void navigate_to (string raw_uri) {
        var current_uri = current_uri;
        Uri new_uri;
        try {
            new_uri = Uri.parse (raw_uri, current_uri);
        } catch (Core.UriError e) {
            warning ("Error parsing %s, will skip loading! Error: %s", raw_uri, e.message);
            return;
        }

        if (new_uri.scheme != "gemini") {
            try {
                Gtk.show_uri_on_window (null, new_uri.to_string (), (uint32) Gdk.CURRENT_TIME);
            } catch (Error e) {
                warning ("Error launching non-gemini Uri %s! Error: %s", new_uri.to_string (), e.message);
            }
            return;
        }

        lock (loading) {
            if (loading) {
                return;
            } else {
                loading = true;
            }

            manager.client.load.begin (new_uri, null, (obj, res) => {
                var response = manager.client.load.end (res);
                var loaded_uri = response.uri;
                var previous_uri = current_uri;
                if (loaded_uri.to_string () != previous_uri.to_string ()) {
                    if (_history_index < _history.length - 1) {
                        _history = _history [0:_history_index + 1];
                    }

                    _history += loaded_uri;
                    if (_history.length > max_history ()) {
                        _history = _history[1:_history.length];
                    }

                    _history_index = _history.length - 1;
                    manager.save (this);
                }
                response_received (response);
            });
        }
    }

    private int max_history () {
        return manager.settings.get_int ("max-history");
    }
}

