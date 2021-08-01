public class Starfish.Core.TabManager : Object {

    public Settings settings { get; construct; }
    public SessionManager session_manager { get; construct; }
    public Gee.List<Tab> tabs { get; construct; }

    public int focused_tab_index {
        get { return settings.get_int ("focused-tab"); }
        set { settings.set_int ("focused-tab", value); }
    }

    public TabManager (Settings settings) {
        Object (
            settings: settings,
            session_manager: new SessionManager.backed_by (settings),
            tabs: new Gee.ArrayList<Tab> ()
        );
    }

    construct {
        var session_ids = settings.get_strv ("tabs");
        foreach (var id in session_ids) {
            var session = session_manager.load (id);
            var tab = new Tab (id, session);
            tabs.add (tab);
        }
    }

    public Tab new_tab () {
        var id = Uuid.string_random ();
        var session = session_manager.load (id);
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
        session_manager.remove (tab.session);
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
        settings.set_strv ("tabs", session_ids);
    }
}

