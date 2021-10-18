public class Starfish.Core.Session : Object {

    private string _name;
    private Uri[] _history;
    private int _history_index;
    private SessionManager manager { get; set; }

    public bool loading { get; set; default = false; }
    public string name { get { return _name; } }
    public Core.CertInfo? cert_info { get; set; default = null; }
    public Gee.List<Uri> history {
        owned get { return new Gee.ArrayList<Uri>.wrap (_history); }
    }

    public Theme theme {
        get { return manager.theme; }
    }

    public Settings settings {
        get { return manager.settings; }
    }

    public BookmarksManager bookmarks_manager {
        get { return manager.bookmarks_manager; }
    }

    public CertManager cert_manager {
        get { return manager.cert_manager; }
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

    public void push_uri_onto_history_before_init (Uri uri) {
        update_history_with_uri (uri);
    }

    public void init () {
        lock (loading) {
            if (loading) {
                return;
            } else {
                loading = true;
            }

            var starting_uri = current_uri;
            manager.client.load.begin (starting_uri, null, true, false, (obj, res) => {
                var response = manager.client.load.end (res);
                cert_info = response.cert_info;
                var loaded_uri = response.uri;
                if (current_uri.to_string() != loaded_uri.to_string ()) {
                    _history[_history_index] = loaded_uri;
                    current_uri = loaded_uri;
                    manager.save (this);
                }
                response_received (response);
            });
        }
    }

    public bool has_back () {
        return _history_index > 0;
    }

    public void navigate_back () {
        if (!has_back ()) {
            return;
        }

        lock (loading) {
            if (loading) {
                return;
            } else {
                loading = true;
            }

            var uri = _history[_history_index - 1];
            manager.client.load.begin (uri, null, true, false, (obj, res) => {
                var response = manager.client.load.end (res);
                cert_info = response.cert_info;
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

    public bool has_forward () {
        return _history_index < _history.length - 1;
    }

    public void navigate_forward () {
        if (!has_forward ()) {
            return;
        }

        lock (loading) {
            if (loading) {
                return;
            } else {
                loading = true;
            }

            var uri = _history[_history_index + 1];
            manager.client.load.begin (uri, null, true, false, (obj, res) => {
                var response = manager.client.load.end (res);
                cert_info = response.cert_info;
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

    public void navigate_to (
        string raw_uri,
        bool accept_mismatched_cert = false
    ) {
        Uri new_uri;
        try {
            new_uri = Uri.parse (raw_uri, current_uri);
        } catch (Core.UriError e) {
            warning ("Error parsing %s, will skip loading! Error: %s", raw_uri, e.message);
            return;
        }

        manager.client.supports.begin (new_uri, null, (obj, res) => {
            var is_supported_nativelly = manager.client.supports.end (res);
            if (!is_supported_nativelly) {
                delegate_opening_of (new_uri);
            } else {
                lock (loading) {
                    if (loading) {
                        return;
                    } else {
                        loading = true;
                    }

                    manager.client.load.begin (new_uri, null, true, accept_mismatched_cert, (obj, res) => {
                        var response = manager.client.load.end (res);
                        cert_info = response.cert_info;
                        update_history_on_response (response);
                        response_received (response);
                    });
                }
            }
        });

    }

    public void navigate_up () {
        var new_uri = current_uri.one_up ();
        if (new_uri == current_uri) {
            return;
        }

        lock (loading) {
            if (loading) {
                return;
            } else {
                loading = true;
            }

            navigate_one_level_up_from (new_uri);
        }
    }

    public void navigate_to_root () {
        var new_uri = current_uri.root ();
        if (new_uri == current_uri) {
            return;
        }

        navigate_to (new_uri.to_string ());
    }

    private void navigate_one_level_up_from (Uri uri) {
        manager.client.load.begin (uri, null, false, false, (obj, res) => {
            var response = manager.client.load.end (res);
            if (response.is_success) {
                cert_info = response.cert_info;
                update_history_on_response (response);
                response_received (response);
            } else {
                response.close ();
                var new_uri = response.uri.one_up ();
                if (new_uri.to_string () == uri.to_string ()) {
                    if (response.is_redirect) {
                        try {
                            new_uri = Uri.parse (response.meta, uri);
                            navigate_one_level_up_from (new_uri);
                        } catch (Core.UriError err) {
                            cert_info = response.cert_info;
                            update_history_on_response (response);
                            response_received (response);
                        }
                    } else {
                        cert_info = response.cert_info;
                        update_history_on_response (response);
                        response_received (response);
                    }
                } else {
                    navigate_one_level_up_from (new_uri);
                }
            }
        });
    }

    private void delegate_opening_of (Uri uri) {
        try {
            Gtk.show_uri_on_window (null, uri.to_string (), (uint32) Gdk.CURRENT_TIME);
        } catch (Error e) {
            warning ("Error launching non-gemini Uri %s! Error: %s", uri.to_string (), e.message);
        }
    }

    private void update_history_on_response (Response response) {
        var loaded_uri = response.uri;
        update_history_with_uri (loaded_uri);
    }

    private void update_history_with_uri (Uri uri) {
        if (uri.to_string () != current_uri.to_string ()) {
            if (_history_index < _history.length - 1) {
                _history = _history [0:_history_index + 1];
            }

            _history += uri;
            if (_history.length > max_history ()) {
                _history = _history[1:_history.length];
            }

            _history_index = _history.length - 1;
            manager.save (this);
        }
    }

    private int max_history () {
        return manager.settings.get_int ("max-history");
    }
}

