public class Starfish.UI.Application : Gtk.Application {

    public static string ID = "hr.from.josipantolis.starfish";

    public Core.Client client { get; construct; }
    public Settings settings { get; construct; }
    private Core.SessionManager manager;

    public Application () {
        Object (
            application_id: ID,
            flags: ApplicationFlags.HANDLES_OPEN,
            client: new Starfish.Core.Client (),
            settings: new Settings ("hr.from.josipantolis.starfish")
        );
    }

    construct {
        manager = new Core.SessionManager.backed_by (settings);
    }

    protected override void activate () {
        var default_session = manager.load ("default");
        show_main_window (default_session);
    }

    protected override void open (File[] files, string hint) {
        var default_session = manager.load ("default");
        push_gemini_links (default_session, files);
        show_main_window (default_session);
    }

    private void show_main_window (Core.Session session) {
        var main_window = new Window (this, session);
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

    private void push_gemini_links (Core.Session session, File[] files) {
        foreach (File f in files) {
            session.push_uri_onto_history_before_init (f.get_uri ());
        }
    }
}

