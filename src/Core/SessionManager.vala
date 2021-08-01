public class Starfish.Core.SessionManager : Object {

    public Settings settings { get; construct; }
    public SessionStorage storage { get; construct; }
    public Client client { get; construct; }
    public Theme theme { get; construct; }

    private Variant sessions;

    public SessionManager.backed_by (Settings settings) {
        this (
            settings,
            new SettingsBackedSessionStorage (settings),
            new Client (),
            new Theme.os (settings)
        );
    }

    public SessionManager (
        Settings settings,
        SessionStorage storage,
        Client client,
        Theme theme
    ) {
        Object (
            settings: settings,
            storage: storage,
            client: client,
            theme: theme
        );
    }

    construct {
        sessions = storage.load ();
    }

    public Session[] load_all () {
        Session[] res = {};
        foreach (var session_var in sessions) {
            res += to_session (session_var);
        }

        return res;
    }

    public Session load (string name) {
        var session = find_session_by_name (name);
        if (session != null) {
            return session;
        }

        session = new_session (name);
        save (session);
        return session;
    }

    public void save (Session session) {
        Variant[] new_sessions = {};
        var idx = find_session_idx_by_name (session.name);
        var iter = sessions.iterator ();
        var i = 0;
        Variant? session_var = iter.next_value ();
        while (session_var != null) {
            if (i != idx) {
                new_sessions += session_var;
            } else {
                new_sessions += to_variant (session);
            }

            session_var = iter.next_value ();
            i++;
        }

        if (idx == -1) {
            new_sessions += to_variant (session);
        }

        var element_type = sessions.get_type ().element ();
        sessions = new Variant.array (element_type, new_sessions);
        storage.save (sessions);
    }

    public void remove (Session session) {
        Variant[] new_sessions = {};
        var idx = find_session_idx_by_name (session.name);
        var iter = sessions.iterator ();
        var i = 0;
        Variant? session_var = iter.next_value ();
        while (session_var != null) {
            if (i != idx) {
                new_sessions += session_var;
            }

            session_var = iter.next_value ();
            i++;
        }

        var element_type = sessions.get_type ().element ();
        sessions = new Variant.array (element_type, new_sessions);
        storage.save (sessions);
    }

    private Session? find_session_by_name (string name) {
        var iter = sessions.iterator ();
        string session_name;
        int history_index;
        VariantIter? history_var;
        while (iter.next ("(sias)", out session_name, out history_index, out history_var)) {
            if (session_name == name) {
                Uri[] history = {};
                string raw_uri;
                while (history_var.next ("s", out raw_uri)) {
                    try {
                        history += Uri.parse (raw_uri);
                    } catch (UriError e) {
                        warning ("Found an invalid Uri `%s` in seralized history, will skip it for now. Error: %s", raw_uri, e.message);
                    }
                }
                return new Session (session_name, history, history_index, this);
            }
        }

        return null;
    }

    private Session new_session (string name) {
        var raw_homepage_uri = settings.get_string ("homepage");
        Uri homepage_uri;
        try {
            homepage_uri = Uri.parse (raw_homepage_uri);
        } catch (UriError e) {
            warning ("Found and invalid Uri `%s` in serialized homepage, will use gemini://gemini.circumlunar.space/ instead. Error: %s", raw_homepage_uri, e.message);
            homepage_uri = new Uri ("gemini", null, "gemini.circumlunar.space", -1, "/");
        }
        Uri[] history = {homepage_uri};
        return new Session (name, history, 0, this);
    }

    private Session to_session (Variant session_var) {
        var i = session_var.iterator ();
        var name = i.next_value ().get_string ();
        var index = ((int) i.next_value ().get_uint16 ());
        var raw_history = i.next_value ().get_strv ();
        var history = to_uris (raw_history);
        return new Session (name, history, index, this);
    }

    private Uri[] to_uris (string[]? raw_uris) {
        if (raw_uris == null) {
            return new Uri[0];
        }

        Uri[] uris = {};
        foreach (var raw_uri in raw_uris) {
            try {
                uris += Uri.parse (raw_uri);
            } catch (UriError e) {
                warning ("Found an invalid Uri `%s` in seralized history, will skip it for now. Error: %s", raw_uri, e.message);
            }
        }

        return uris;
    }

    private int find_session_idx_by_name (string name) {
        var iter = sessions.iterator ();
        Variant? session_var = iter.next_value ();
        int idx = 0;
        while (session_var != null) {
            var i = session_var.iterator ();
            string? session_name = null;
            i.next ("s", out session_name);
            if (session_name == name) {
                return idx;
            }

            session_var = iter.next_value ();
            idx++;
        }

        return -1;
    }

    private Variant to_variant (Session session) {
        string[] raw_history = {};
        foreach (var uri in session.history) {
            raw_history += uri.to_string ();
        }

        return new Variant.tuple ({
            new Variant.string (session.name),
            new Variant("i", session.history_index),
            new Variant.strv (raw_history)
        });
    }
}

