public class Starfish.Core.SessionManager : Object {

    public Settings settings { get; construct; }
    public Storage storage { get; construct; }
    public Client client { get; construct; }
    public Theme theme { get; construct; }
    public BookmarksManager bookmarks_manager { get; construct; }
    public CertManager cert_manager { get; construct; }

    private Variant sessions;

    public SessionManager.backed_by (Settings settings) {
        var cert_manager = new CertManager ();
        this (
            settings,
            new SettingsBackedStorage (settings),
            new Client (cert_manager),
            new Theme.os (settings),
            new BookmarksManager (),
            cert_manager
        );
    }

    public SessionManager (
        Settings settings,
        Storage storage,
        Client client,
        Theme theme,
        BookmarksManager bookmarks_manager,
        CertManager cert_manager
    ) {
        Object (
            settings: settings,
            storage: storage,
            client: client,
            theme: theme,
            bookmarks_manager: bookmarks_manager,
            cert_manager: cert_manager
        );
    }

    construct {
        sessions = storage.load_sessions ();
    }

    public Session[] load_all () {
        Session[] res = {};
        foreach (var session_var in sessions) {
            res += to_session (session_var);
        }

        return res;
    }

    public Session load (string name, string? raw_uri = null) {
        var session = find_session_by_name (name);
        if (session != null) {
            return session;
        }

        session = new_session (name, raw_uri);
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
        storage.save_sessions (sessions);
    }

    public void remove (Session session) {
        remove_session_by_name (session.name);
    }

    public void remove_session_by_name (string session_name) {
        Variant[] new_sessions = {};
        var idx = find_session_idx_by_name (session_name);
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
        storage.save_sessions (sessions);
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

    private Session new_session (string name, string? raw_uri = null) {
        var raw_uri_to_load = raw_uri ?? storage.load_homepage ();
        Uri uri_to_load;
        try {
            uri_to_load = Uri.parse (raw_uri_to_load);
        } catch (UriError e) {
            warning ("Found and invalid Uri `%s` in serialized homepage, will use gemini://gemini.circumlunar.space/ instead. Error: %s", raw_uri_to_load, e.message);
            uri_to_load = new Uri ("gemini", null, "gemini.circumlunar.space", -1, "/");
        }
        Uri[] history = {uri_to_load};
        return new Session (name, history, 0, this);
    }

    private Session to_session (Variant session_var) {
        var i = session_var.iterator ();
        var name = i.next_value ().get_string ();
        var index = ((int) i.next_value ().get_int32 ());
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

