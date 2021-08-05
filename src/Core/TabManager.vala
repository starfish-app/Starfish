public class Starfish.Core.TabManager : Object {

    public Settings settings { get; construct; }
    public Storage storage { get; construct; }
    public SessionManager session_manager { get; construct; }
    public Gee.List<Tab> tabs { get; construct; }
    public int max_restorable_tabs {
        get { return settings.get_int ("max-tabs-history"); }
    }

    public int focused_tab_index {
        get { return storage.load_focused_tab (); }
        set { storage.save_focused_tab (value); }
    }

    public TabManager.backed_by (Settings settings) {
        this (
            settings,
            new SettingsBackedStorage (settings),
            new SessionManager.backed_by (settings)
        );
    }

    public TabManager (
        Settings settings,
        Storage storage,
        SessionManager session_manager
    ) {
        Object (
            settings: settings,
            storage: storage,
            session_manager: session_manager,
            tabs: new Gee.ArrayList<Tab> ()
        );
    }

    construct {
        var session_ids = storage.load_tabs ();
        foreach (var id in session_ids) {
            var session = session_manager.load (id);
            var tab = new Tab (id, session);
            tabs.add (tab);
        }

        clean_up_leftover_sessions ();
    }

    private void clean_up_leftover_sessions () {
        var opened_session_ids = new Gee.HashSet<string> ();
        foreach (var tab in tabs) {
            opened_session_ids.add (tab.id);
        }

        foreach (var session in session_manager.load_all ()) {
            if (!opened_session_ids.contains (session.name)) {
                session_manager.remove_session_by_name (session.name);
            }
        }
    }

    public Tab new_tab (string? raw_uri = null) {
        var id = Uuid.string_random ();
        return load_or_create_tab (id, raw_uri);
    }

    public Tab restore_tab (string id) {
        return load_or_create_tab (id);
    }

    private Tab load_or_create_tab (string id, string? raw_uri = null) {
        var session = session_manager.load (id, raw_uri);
        var tab = new Tab (id, session);
        tabs.add (tab);
        store_tabs_into_settings ();
        return tab;
    }

    public void close_tab (Tab tab) {
        close_tab_at (tabs.index_of (tab));
    }

    public void close_tab_at (int tab_index) {
        var tab = tabs[tab_index];
        tab.session.cancel_loading ();
        tabs.remove_at (tab_index);
        store_tabs_into_settings ();
        if (tab_index <= focused_tab_index && tabs.size > 0) {
            focused_tab_index--;
        }
    }

    public void move_tab (Tab tab, int new_index) {
        var old_index = tabs.index_of (tab);
        if (old_index == focused_tab_index) {
            focused_tab_index = new_index;
        }

        tabs.remove_at (old_index);
        tabs.insert (new_index, tab);
        store_tabs_into_settings ();
    }

    private void store_tabs_into_settings () {
        var session_ids = new string[tabs.size];
        var i = 0;
        foreach (var tab in tabs) {
            session_ids[i++] = tab.id;
        }
        storage.save_tabs (session_ids);
    }
}

