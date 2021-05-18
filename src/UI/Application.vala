public class Starfish.UI.Application : Gtk.Application {

    public static string ID = "hr.from.josipantolis.starfish";

    public Core.Client client { get; construct; }
    public Settings settings { get; construct; }
    private Core.SessionManager manager;

    public Application () {
        Object (
            application_id: ID,
            flags: ApplicationFlags.FLAGS_NONE,
            client: new Starfish.Core.Client (),
            settings: new Settings ("hr.from.josipantolis.starfish")
        );
    }

    construct {
        manager = new Core.SessionManager.backed_by (settings);
    }

    protected override void activate () {
        var default_session = manager.load ("default");
        var main_window = new Window (this, default_session);
        main_window.show_all ();
    }
}

