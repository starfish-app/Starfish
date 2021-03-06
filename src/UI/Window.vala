public class Starfish.UI.Window : Hdy.ApplicationWindow {

    private HeaderBar header;
    private Granite.Widgets.DynamicNotebook notebook;
    private PreferencesDialog? preferences_dialog = null;
    private uint configure_id;

    public Settings settings { get; construct; }
    public Core.TabManager tab_manager { get; construct; }

    public const string ACTION_GROUP_PREFIX = "win";
    public const string ACTION_PREFIX = ACTION_GROUP_PREFIX + ".";
    public const string ACTION_RELOAD = "reload";
    public const string ACTION_STOP = "stop";
    public const string ACTION_GO_HOME = "go-home";
    public const string ACTION_GO_BACK = "go-back";
    public const string ACTION_GO_FORWARD = "go-forward";
    public const string ACTION_GO_UP = "go-up";
    public const string ACTION_GO_TO_ROOT = "go-to-root";
    public const string ACTION_GO_TO_NEXT = "go-to-next";
    public const string ACTION_GO_TO_PREVIOUS = "go-to-previous";
    public const string ACTION_ZOOM_OUT = "zoom-out";
    public const string ACTION_RESET_ZOOM = "reset-zoom";
    public const string ACTION_ZOOM_IN = "zoom-in";
    public const string ACTION_OPEN_PREFERENCES = "open-preferences";
    public const string ACTION_OPEN_BOOKMARKS = "open-bookmarks";
    public const string ACTION_ADD_BOOKMARK = "add-bookmark";
    public const string ACTION_REMOVE_BOOKMARK = "remove-bookmark";
    public const string ACTION_LOAD_URI = "load-uri";
    public const string ACTION_LOAD_URI_IN_NEW_TAB = "load-uri-in-new-tab";
    public const string ACTION_SEARCH = "search";

    public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

    private const ActionEntry[] ACTION_ENTRIES = {
        {ACTION_RELOAD, on_reload},
        {ACTION_STOP, on_stop},
        {ACTION_GO_HOME, on_go_home},
        {ACTION_GO_BACK, on_go_back},
        {ACTION_GO_FORWARD, on_go_forward},
        {ACTION_GO_UP, on_go_up},
        {ACTION_GO_TO_ROOT, on_go_to_root},
        {ACTION_ZOOM_OUT, on_zoom_out},
        {ACTION_RESET_ZOOM, on_reset_zoom},
        {ACTION_ZOOM_IN, on_zoom_in},
        {ACTION_OPEN_PREFERENCES, on_open_preferences},
        {ACTION_OPEN_BOOKMARKS, on_open_bookmarks},
        {ACTION_ADD_BOOKMARK, on_add_bookmark},
        {ACTION_REMOVE_BOOKMARK, on_remove_bookmark},
        {ACTION_LOAD_URI, on_load_uri, "s"},
        {ACTION_LOAD_URI_IN_NEW_TAB, on_load_uri_in_new_tab, "(sb)"},
        {ACTION_SEARCH, on_search},
    };

    static construct {
        Hdy.init ();
        action_accelerators[ACTION_RELOAD] = "<Control>r";
        action_accelerators[ACTION_GO_HOME] = "<Control>h";
        action_accelerators[ACTION_GO_BACK] = "<alt>Left";
        action_accelerators[ACTION_GO_FORWARD] = "<alt>Right";
        action_accelerators[ACTION_GO_UP] = "<alt>Up";
        action_accelerators[ACTION_ZOOM_OUT] = "<Control>minus";
        action_accelerators[ACTION_RESET_ZOOM] = "<Control>0";
        action_accelerators[ACTION_ZOOM_IN] = "<Control>plus";
        action_accelerators[ACTION_ZOOM_IN] = "<Control>equal";
        action_accelerators[ACTION_SEARCH] = "<Control>f";
    }

    public Window (Starfish.UI.Application application, Core.TabManager tab_manager) {
        Object (
            application: application,
            settings: application.settings,
            tab_manager: tab_manager,
            title: _("Starfish"),
            height_request: 400,
            width_request: 600
        );
    }

    construct {
        setup_actions ();
        link_to_settings ();

        notebook = new Granite.Widgets.DynamicNotebook () {
            expand = true,
            can_focus = false,
            allow_restoring = true,
            max_restorable_tabs = tab_manager.max_restorable_tabs
        };

        setup_tabs (notebook);

        var grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        header = new HeaderBar (this, focused_tab_session ());

        grid.add (header);
        grid.add (notebook);
        this.add (grid);
    }

    private void setup_actions () {
        var app = (Application) GLib.Application.get_default ();
        add_action_entries (ACTION_ENTRIES, this);
        foreach (var action in action_accelerators.get_keys ()) {
            app.set_accels_for_action (
                ACTION_PREFIX + action,
                action_accelerators[action].to_array ()
            );
        }

        button_release_event.connect (on_mouse_click_event);
    }

    private void link_to_settings () {
        var window_maximized = settings.get_boolean ("window-maximized");
        if (window_maximized) {
           maximize ();
        }

        var window_size = Gtk.Allocation ();
        settings.get ("window-size", "(ii)", out window_size.width, out window_size.height);
        set_allocation (window_size);

        int window_x, window_y;
        settings.get ("window-position", "(ii)", out window_x, out window_y);
        if (window_x != -1 || window_y != -1) {
            move (window_x, window_y);
        }
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        if (configure_id != 0) {
            GLib.Source.remove (configure_id);
        }

        configure_id = Timeout.add (100, () => {
            configure_id = 0;
            if (is_maximized) {
                settings.set_boolean ("window-maximized", true);
            } else {
                settings.set_boolean ("window-maximized", false);

                Gdk.Rectangle window_size;
                get_allocation (out window_size);
                settings.set ("window-size", "(ii)", window_size.width, window_size.height);

                int window_x, window_y;
                get_position (out window_x, out window_y);
                settings.set ("window-position", "(ii)", window_x, window_y);
            }

            return false;
        });

        return base.configure_event (event);
    }

    private void setup_tabs (Granite.Widgets.DynamicNotebook notebook) {
        var i = 0;
        foreach (var model in tab_manager.tabs) {
            var tab = create_tab (model);
            notebook.insert_tab (tab, i++);
        }
        var previously_focused_index = tab_manager.focused_tab_index;
        notebook.current = notebook.get_tab_by_index (previously_focused_index);

        notebook.new_tab_requested.connect (() => {
            var model = tab_manager.new_tab ();
            var tab = create_tab (model);
            notebook.insert_tab (tab, notebook.n_tabs);
            notebook.current = tab;
        });

        notebook.close_tab_requested.connect ((tab) => {
            var model = ((TabContent) tab.page).tab_model;
            tab_manager.close_tab (model);
            if (notebook.n_tabs == 1) {
                application.quit ();
            }

            return true;
        });

        notebook.tab_reordered.connect ((moved_tab, new_index) => {
            var moved_tab_model = ((TabContent) moved_tab.page).tab_model;
            tab_manager.move_tab (moved_tab_model, new_index);
        });

        notebook.tab_switched.connect ((old_tab, new_tab) => {
            var model = ((TabContent) new_tab.page).tab_model;
            header.session = model.session;
            var focused_index = notebook.get_tab_position (new_tab);
            tab_manager.focused_tab_index = focused_index;
        });

        notebook.tab_restored.connect ((label, tab_id, icon) => {
            var model = tab_manager.restore_tab (tab_id);
            var tab = create_tab (model);
            notebook.insert_tab (tab, notebook.n_tabs);
            notebook.current = tab;
        });
    }

    private Granite.Widgets.Tab create_tab (Core.Tab model) {
        var tab = new Granite.Widgets.Tab (
            model.uri.file_name (),
            null,
            new TabContent (this, model)
        );

        tab.tooltip = model.uri.to_string ();
        tab.restore_data = model.id;
        tab.dropped_callback = (() => {
            tab_manager.session_manager.remove_session_by_name (model.id);
        });

        model.session.notify["loading"].connect ((s, p) => {
            var is_loading = model.session.loading;
            tab.working = is_loading;
            if (!is_loading) {
                tab.label = model.uri.file_name ();
                tab.tooltip = model.uri.to_string ();
            }
        });

        return tab;
    }

    private Core.Session focused_tab_session () {
        var focused_tab = notebook.current;
        var model = ((TabContent) focused_tab.page).tab_model;
        return model.session;
    }

    private void on_reload () {
        var raw_uri = header.address_uri;
        focused_tab_session ().navigate_to (raw_uri);
    }

    private void on_stop () {
        focused_tab_session ().cancel_loading ();
    }

    private void on_go_back () {
        focused_tab_session ().navigate_back ();
    }

    private void on_go_home () {
        var home_uri = settings.get_string ("homepage");
        focused_tab_session ().navigate_to (home_uri);
    }

    private void on_go_forward () {
        focused_tab_session ().navigate_forward ();
    }

    private void on_go_up () {
        focused_tab_session ().navigate_up ();
    }

    private void on_go_to_root () {
        focused_tab_session ().navigate_to_root ();
    }

    private void on_zoom_out () {
        var key = "font-size";
        var default_zoom = settings.get_default_value (key).get_double ();
        var current_zoom = settings.get_double (key);
        var new_zoom = current_zoom - 0.1 * default_zoom;
        if (new_zoom < 0.5 * default_zoom) {
            return;
        }
        settings.set_double (key, new_zoom);
    }

    private void on_reset_zoom () {
        settings.reset ("font-size");
    }

    private void on_zoom_in () {
        var key = "font-size";
        var default_zoom = settings.get_default_value (key).get_double ();
        var current_zoom = settings.get_double (key);
        settings.set_double (key, current_zoom + 0.1 * default_zoom);
    }

    private void on_open_preferences () {
        if (preferences_dialog == null) {
            preferences_dialog = new PreferencesDialog (settings);
            preferences_dialog.show_all ();

            preferences_dialog.destroy.connect (() => {
                preferences_dialog = null;
            });
        }

        preferences_dialog.present ();
    }

    private void on_open_bookmarks () {
        var manager = focused_tab_session ().bookmarks_manager;
        manager.get_bookmarks_uri.begin ((obj, res) => {
            try {
                var uri = manager.get_bookmarks_uri.end (res);
                var model = tab_manager.new_tab (uri.to_string ());
                var tab = create_tab (model);
                notebook.insert_tab (tab, notebook.n_tabs);
                notebook.current = tab;
            } catch (Error err) {
                warning ("Failed to open bookmarks, error: %s", err.message);
            }
        });
    }

    private void on_add_bookmark () {
        var session = focused_tab_session ();
        var uri = session.current_uri;
        var manager = session.bookmarks_manager;
        manager.add_bookmark.begin (uri, "", (obj, res) => {
            try {
                manager.add_bookmark.end (res);
            } catch (Error err) {
                warning ("Failed to add bookmark, error: %s", err.message);
            }
        });
    }

    private void on_remove_bookmark () {
        var session = focused_tab_session ();
        var uri = session.current_uri;
        var manager = session.bookmarks_manager;
        manager.remove_bookmark.begin (uri, (obj, res) => {
            try {
                manager.remove_bookmark.end (res);
            } catch (Error err) {
                warning ("Failed to remove bookmark, error: %s", err.message);
            }
        });
    }

    private void on_load_uri (SimpleAction action, Variant? arg) {
        if (arg == null) {
            warning ("Received null argument in load uri callback, will skip opening new tab.");
            return;
        }

        var raw_uri = arg.get_string ();
        focused_tab_session ().navigate_to (raw_uri);
    }

    private void on_load_uri_in_new_tab (SimpleAction action, Variant? args) {
        if (args == null) {
            warning ("Received null argument in load uri in new tab callback, will skip opening new tab.");
            return;
        }

        var raw_relative_uri = args.get_child_value (0).get_string ();
        var should_focus_new_tab = args.get_child_value (1).get_boolean ();
        try {
            var base_uri = focused_tab_session ().current_uri;
            var uri = Core.Uri.parse (raw_relative_uri, base_uri);
            if (uri.scheme != "gemini" && uri.scheme != "file") {
                focused_tab_session ().navigate_to (uri.to_string ());
            } else {
                var model = tab_manager.new_tab (uri.to_string ());
                var tab = create_tab (model);
                notebook.insert_tab (tab, notebook.n_tabs);
                if (should_focus_new_tab) {
                    notebook.current = tab;
                }
            }
        } catch (Core.UriError err) {
            warning ("Received invalid Uri in load uri in new tab callback: `%s`, will skip opening new tab. Error: %s`", raw_relative_uri, err.message);
        }
    }

    private void on_search () {
        var session = focused_tab_session ();
        session.search_is_open = !session.search_is_open;
    }

    private bool on_mouse_click_event (Gtk.Widget self, Gdk.EventButton event) {
        switch (event.button) {
            case 8:
                on_go_back ();
                return true;
            case 9:
                on_go_forward ();
                return true;
            default:
                return false;
        }
    }
}

