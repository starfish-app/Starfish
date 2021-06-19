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
    private Gtk.Button reset_zoom_button;

    private uint? timeout_id = null;

    public string address_uri {
        get { return address.text; }
    }

    public HeaderBar (ActionMap actions, Core.Session session) {
        this.actions = actions;
        this.session = session;
        hook_reset_zoom_button_to_settings (session.settings);
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

        var menu_button = setup_menu ();
        pack_end (menu_button);
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

    private Gtk.MenuButton setup_menu () {
        var zoom_out_button = setup_button ("zoom-out-symbolic", _("Zoom out"), Window.ACTION_ZOOM_OUT, Gtk.IconSize.MENU);
        var zoom_in_button = setup_button ("zoom-in-symbolic", _("Zoom in"), Window.ACTION_ZOOM_IN, Gtk.IconSize.MENU);
        reset_zoom_button = new Gtk.Button.with_label ("100%") {
            action_name = full_name (Window.ACTION_RESET_ZOOM),
            tooltip_markup = Granite.markup_accel_tooltip (
                Window.action_accelerators[Window.ACTION_RESET_ZOOM].to_array (),
                _("Reset zoom level")
            )
        };

        var font_size_grid = new Gtk.Grid () {
            column_homogeneous = true,
            hexpand = true,
            margin = 12
        };

        font_size_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        font_size_grid.add (zoom_out_button);
        font_size_grid.add (reset_zoom_button);
        font_size_grid.add (zoom_in_button);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        var preferences_button = new Gtk.ModelButton () {
            text = _("Preferences"),
            action_name = full_name (Window.ACTION_OPEN_PREFERENCES)
        };

        var menu_grid = new Gtk.Grid () {
            margin_bottom = 3,
            orientation = Gtk.Orientation.VERTICAL,
            width_request = 200
        };

        menu_grid.attach (font_size_grid, 0, 0, 3, 1);
        menu_grid.attach (separator, 0, 1, 3, 1);
        menu_grid.attach (preferences_button, 0, 2, 3);
        menu_grid.show_all ();

        var menu = new Gtk.Popover (null);
        menu.add (menu_grid);

        return new Gtk.MenuButton () {
            image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR),
            tooltip_text = _("Menu"),
            popover = menu
        };
    }

    private Gtk.Button setup_button (string icon, string name, string action, Gtk.IconSize size = Gtk.IconSize.LARGE_TOOLBAR) {
        return new Gtk.Button.from_icon_name (icon, size) {
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

    private void hook_reset_zoom_button_to_settings (Settings settings) {
        reset_zoom_button.label = current_zoom_percent (settings);
        settings.changed.connect ((key) => {
            if (key == "font-size") {
                reset_zoom_button.label = current_zoom_percent (settings);
            }
        });
    }

    private string current_zoom_percent (Settings settings) {
        var default_zoom = settings.get_default_value ("font-size").get_double ();
        var zoom_percent = (settings.get_double ("font-size") / default_zoom) * 100;
        return "%.0f%%".printf (zoom_percent);
    }
}
