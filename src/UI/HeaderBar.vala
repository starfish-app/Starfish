public class Starfish.UI.HeaderBar : Hdy.HeaderBar {

    private Core.Session _session;
    private ulong[] _session_subs = {};
    public Core.Session session {
        get { return _session; }
        set {
            foreach (var sub_id in _session_subs) {
                session.disconnect (sub_id);
            }

            _session_subs = {};
            _session = value;
            _session_subs += _session.notify["loading"].connect ((s, p) => {
                if (session.loading) {
                    disable_buttons ();
                    start_pulsing ();
                    show_stop_button ();
                } else {
                    enable_buttons ();
                    stop_pulsing ();
                    show_reload_button ();
                }
            });

            _session_subs += _session.response_received.connect (response => {
                address.text = response.uri.to_string ();
            });
        }
    }

    private static Gtk.CssProvider address_style_provider;

    static construct {
        address_style_provider = new Gtk.CssProvider ();
        address_style_provider.load_from_resource ("hr/from/josipantolis/starfish/AddressEntry.css");
    }

    private unowned ActionMap actions;

    private Gtk.Grid title_widget;
    private Gtk.Entry address;
    private Gtk.Button reload_button;
    private Gtk.Button stop_button;
    private Gtk.Button back_button;
    private Gtk.Button forward_button;
    private Gtk.Button home_button;

    private uint? timeout_id = null;

    public string address_uri {
        get { return address.text; }
    }

    public HeaderBar (ActionMap actions) {
        this.actions = actions;
    }

    construct {
        show_close_button = true;
        hexpand = true;

        address = setup_address ();
        reload_button = setup_button ("go-jump", _("Reload"), Window.ACTION_RELOAD);
        stop_button = setup_button ("media-playback-stop", _("Stop"), Window.ACTION_STOP);
        title_widget = new Gtk.Grid () {
            column_spacing = 8
        };

        title_widget.attach (address, 0, 0);
        show_reload_button ();
        custom_title = title_widget;

        back_button = setup_button ("edit-undo", _("Go back"), Window.ACTION_GO_BACK);
        pack_start (back_button);
        forward_button = setup_button ("edit-redo", _("Go forward"), Window.ACTION_GO_FORWARD);
        pack_start (forward_button);
        home_button = setup_button ("go-home", _("Go home"), Window.ACTION_GO_HOME);
        pack_start (home_button);
    }

    private void disable_buttons () {
        reload_button.sensitive = false;
        back_button.sensitive = false;
        forward_button.sensitive = false;
        home_button.sensitive = false;
    }

    private void enable_buttons () {
        reload_button.sensitive = true;
        back_button.sensitive = true;
        forward_button.sensitive = true;
        home_button.sensitive = true;
    }

    private void show_reload_button () {
        title_widget.remove_column (1);
        title_widget.attach_next_to (reload_button, address, Gtk.PositionType.RIGHT);
        title_widget.show_all ();
    }

    private void show_stop_button () {
        title_widget.remove_column (1);
        title_widget.attach_next_to (stop_button, address, Gtk.PositionType.RIGHT);
        title_widget.show_all ();
    }

    private void start_pulsing () {
        if (timeout_id != null) {
            stop_pulsing ();
        }

        address.progress_pulse_step = 0.1;
        timeout_id = Timeout.add (100, () => {
            address.progress_pulse ();
            return true;
        });
    }

    private void stop_pulsing () {
        if (timeout_id == null) {
            return;
        }

        address.progress_fraction = 0;
        address.progress_pulse_step = 0;
        Source.remove (timeout_id);
        timeout_id = null;
    }

    private Gtk.Entry setup_address () {
        var address = new Gtk.Entry () {
            hexpand = true
        };

        unowned Gtk.StyleContext style_ctx = address.get_style_context ();
        style_ctx.add_provider (address_style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        address.activate.connect ((a) => {
            var action = actions.lookup_action (Window.ACTION_RELOAD);
            action.activate (null);
        });

        return address;
    }

    private Gtk.Button setup_button (string icon, string name, string action) {
        return new Gtk.Button.from_icon_name (
            icon,
            Gtk.IconSize.LARGE_TOOLBAR
        ) {
            action_name = full_name (action),
            tooltip_markup = Granite.markup_accel_tooltip (
                Window.action_accelerators[action].to_array (),
                name
            )
        };
    }

    private string full_name (string local_action_name) {
        return Window.ACTION_PREFIX + local_action_name;
    }
}

