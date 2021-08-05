public class Starfish.UI.Application : Gtk.Application {

    public static string ID = "hr.from.josipantolis.starfish";

    public Core.Client client { get; construct; }
    public Settings settings { get; construct; }
    private Core.TabManager manager;

    public Application () {
        Object (
            application_id: ID,
            flags: ApplicationFlags.HANDLES_OPEN,
            client: new Starfish.Core.Client (),
            settings: new Settings ("hr.from.josipantolis.starfish")
        );
    }

    construct {
        manager = new Core.TabManager.backed_by (settings);
    }

    protected override void activate () {
        show_main_window ();
    }

    protected override void open (File[] files, string hint) {
        add_new_tabs_for (files);
        show_main_window ();
    }

    private void show_main_window () {
        if (manager.tabs.size == 0) {
            manager.new_tab ();
        }

        var main_window = new Window (this, manager);
        link_dark_mode_settings ();
        main_window.show_all ();
    }

    private void link_dark_mode_settings () {
        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });
    }

    private void add_new_tabs_for (File[] files) {
        foreach (File file in files) {
            var raw_uri = file.get_uri ();
            Core.Uri uri;
            try {
                uri = Core.Uri.parse (raw_uri, new Core.Uri ());
            } catch (Core.UriError e) {
                warning ("Error parsing %s, will skip loading! Error: %s", raw_uri, e.message);
                continue;
            }

            if (uri.scheme != "gemini" && uri.scheme != "file") {
                warning ("Scheme of %s is neither gemini nor file, will skip loading!", raw_uri);
                continue;
            }
            var new_tab = manager.new_tab ();
            new_tab.session.push_uri_onto_history_before_init (uri);
            manager.focused_tab_index = manager.tabs.size - 1;
        }
    }
}

