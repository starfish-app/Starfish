public class Starfish.UI.Application : Gtk.Application {

    public Settings settings { get; construct; }
    public Core.TabManager manager { get; construct; }
    private Window? main_window;

    public Application () {
        var settings = new Settings ("hr.from.josipantolis.starfish");
        Object (
            application_id: "hr.from.josipantolis.starfish",
            flags: ApplicationFlags.HANDLES_OPEN,
            settings: settings,
            manager: new Core.TabManager.backed_by (settings)
        );
    }

    protected override void activate () {
        if (main_window == null) {
            main_window = show_main_window ();
        } else {
            main_window.present ();
        }
    }

    protected override void open (File[] files, string hint) {
        if (main_window == null) {
            handle_gemini_files (files, (uri) => {
                var new_tab = manager.new_tab ();
                new_tab.session.push_uri_onto_history_before_init (uri);
                manager.focused_tab_index = manager.tabs.size - 1;
            });
            main_window = show_main_window ();
        } else {
            handle_gemini_files (files, (uri) => {
                var action_args = new Variant.tuple ({
                    new Variant.string (uri.to_string ()),
                    new Variant.boolean (true)
                });

                main_window.activate_action (
                    Window.ACTION_LOAD_URI_IN_NEW_TAB,
                    action_args
                );
            });
            main_window.present ();
        }
    }

    private Window show_main_window () {
        if (manager.tabs.size == 0) {
            manager.new_tab ();
        }

        var window = new Window (this, manager);
        link_dark_mode_settings ();
        window.show_all ();
        return window;
    }

    private void link_dark_mode_settings () {
        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });
    }

    private void handle_gemini_files (File[] files, UriHandler open_uri) {
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

            open_uri (uri);
        }
    }
}

private delegate void UriHandler (Starfish.Core.Uri uri);

