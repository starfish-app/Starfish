public class Starfish.UI.Window : Hdy.ApplicationWindow {

    private HeaderBar header;
    private ContentStack content;
    private uint configure_id;

    public Settings settings { get; construct; }
    public Core.Session session { get; construct; }

    public const string ACTION_GROUP_PREFIX = "win";
    public const string ACTION_PREFIX = ACTION_GROUP_PREFIX + ".";
    public const string ACTION_RELOAD = "reload";
    public const string ACTION_STOP = "stop";
    public const string ACTION_GO_HOME = "go-home";
    public const string ACTION_GO_BACK = "go-back";
    public const string ACTION_GO_FORWARD = "go-forward";
    public const string ACTION_GO_UP = "go-up";
    public const string ACTION_GO_TO_TOP = "go-to-top";
    public const string ACTION_GO_TO_NEXT = "go-to-next";
    public const string ACTION_GO_TO_PREVIOUS = "go-to-previous";

    public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

    private const ActionEntry[] ACTION_ENTRIES = {
        {ACTION_RELOAD, on_reload},
        {ACTION_STOP, on_stop},
        {ACTION_GO_HOME, on_go_home},
        {ACTION_GO_BACK, on_go_back},
        {ACTION_GO_FORWARD, on_go_forward}
    };

    static construct {
        Hdy.init ();
        action_accelerators[ACTION_RELOAD] = "<Control>r";
        action_accelerators[ACTION_GO_HOME] = "<Control>h";
        action_accelerators[ACTION_GO_BACK] = "<alt>Left";
        action_accelerators[ACTION_GO_FORWARD] = "<alt>Right";
    }


    public Window (Starfish.UI.Application application, Core.Session session) {
        Object (
            application: application,
            settings: application.settings,
            session: session,
            title: _("Starfish"),
            height_request: 400,
            width_request: 600
        );
    }

    construct {
        setup_actions ();
        link_to_settings ();

        header = new HeaderBar (this);
        header.session = session;

        var input_view = new InputView (session);
        input_view.submit.connect (on_input_submit);
        var text_view = new PageTextView (session);
        text_view.link_event.connect (on_link_event);
        var error_view = new PageErrorView (session);
        error_view.link_event.connect (on_link_event);
        var image_view = new PageImageView (session);
        content = new ContentStack.with_views (
            "text-response", text_view,
            "error-response", error_view,
            "input", input_view,
            "image", image_view
        );

        var grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        grid.add (header);
        grid.add (content);
        this.add (grid);

        session.notify["loading"].connect ((s, p) => {
            if (session.loading) {
                content.clear ();
            }
        });

        session.response_received.connect (response => {
            content.display (response);
        });

        session.init ();
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

    private void on_input_submit (InputView view, string input) {
        var query = "?" + Core.Uri.encode (input);
        session.navigate_to (query);
    }

    private void on_link_event (PageTextView page, LinkEvent event) {
        switch (event.event_type) {
            case LinkEventType.HOVER_ENTER:
                var gdk_window = page.get_window (Gtk.TextWindowType.TEXT);
                if (gdk_window != null) {
                    var pointer = new Gdk.Cursor.from_name (
                        gdk_window.get_display (),
                        "pointer"
                    );

                    gdk_window.set_cursor (pointer);
                }

                return;
            case LinkEventType.HOVER_EXIT:
                var gdk_window = page.get_window (Gtk.TextWindowType.TEXT);
                if (gdk_window != null) {
                    var text = new Gdk.Cursor.from_name (
                        gdk_window.get_display (),
                        "text"
                    );

                    gdk_window.set_cursor (text);
                }

                return;
            case LinkEventType.LEFT_MOUSE_CLICK:
                var raw_uri = event.link_url;
                session.navigate_to (raw_uri);
                return;
        }
    }

    private void on_reload () {
        var raw_uri = header.address_uri;
        session.navigate_to (raw_uri);
    }

    private void on_stop () {
        session.cancel_loading ();
    }

    private void on_go_back () {
        session.navigate_back ();
    }

    private void on_go_home () {
        var home_uri = settings.get_string ("homepage");
        session.navigate_to (home_uri);
    }

    private void on_go_forward () {
        session.navigate_forward ();
    }
}

