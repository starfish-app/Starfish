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
                on_session_change ();
            });

            _session_subs += _session.response_received.connect (response => {
                on_session_change ();
            });

            on_session_change ();
        }
    }

    private static Gtk.CssProvider address_style_provider;

    static construct {
        address_style_provider = new Gtk.CssProvider ();
        address_style_provider.load_from_resource ("hr/from/josipantolis/starfish/AddressEntry.css");
    }

    private unowned Window window;

    private Gtk.Grid title_widget;
    private Gtk.Entry address;
    private Gtk.Button stop_reload_button;
    private Gtk.Image reload_icon;
    private Gtk.Image stop_icon;
    private Gtk.Button back_button;
    private Gtk.Button forward_button;
    private Gtk.Button up_button;
    private Gtk.Button root_button;
    private Gtk.Button home_button;
    private Gtk.Button bookmarks_button;
    private Gtk.Button reset_zoom_button;
    private CertPopover cert_popover;

    private uint? timeout_id = null;

    public string address_uri {
        get { return address.text; }
    }

    public HeaderBar (Window window, Core.Session session) {
        this.window = window;
        this.session = session;
        hook_reset_zoom_button_to_settings (session.settings);
    }

    construct {
        show_close_button = true;
        hexpand = true;
        spacing = 1;

        reload_icon = new Gtk.Image.from_icon_name ("go-jump", Gtk.IconSize.LARGE_TOOLBAR);
        stop_icon = new Gtk.Image.from_icon_name ("media-playback-stop", Gtk.IconSize.LARGE_TOOLBAR);
        stop_reload_button = setup_button ("go-jump", _("Reload"), Window.ACTION_RELOAD);
        stop_reload_button.sensitive = true;
        back_button = setup_button ("edit-undo", _("Go back"), Window.ACTION_GO_BACK);
        forward_button = setup_button ("edit-redo", _("Go forward"), Window.ACTION_GO_FORWARD);
        up_button = setup_button ("go-up", _("Go up"), Window.ACTION_GO_UP);
        root_button = setup_button ("go-top", _("Go to root"), Window.ACTION_GO_TO_ROOT);
        home_button = setup_button ("go-home", _("Go home"), Window.ACTION_GO_HOME);
        bookmarks_button = setup_button ("user-bookmarks", _("Open bookmarks"), Window.ACTION_OPEN_BOOKMARKS);

        address = setup_address ();
        cert_popover = new CertPopover (address);
        title_widget = new Gtk.Grid () {
            column_spacing = 8,
            hexpand = true
        };
        title_widget.attach (address, 0, 0);
        title_widget.attach (stop_reload_button, 1, 0);
        title_widget.attach (home_button, 2, 0);
        custom_title = title_widget;

        pack_start (up_button);
        pack_start (root_button);
        pack_start (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        pack_start (back_button);
        pack_start (forward_button);
        var menu_button = setup_menu ();
        pack_end (menu_button);
        pack_end (bookmarks_button);
    }

    private void on_session_change () {
        if (_session.loading) {
            disable_buttons ();
            start_pulsing ();
            show_stop_button ();
        } else {
            enable_buttons ();
            stop_pulsing ();
            show_reload_button ();
            update_address_bookmark_icon ();
        }

        address.text = _session.current_uri.to_string ();
        address.primary_icon_name = icon_name_for (_session);
    }

    private void disable_buttons () {
        back_button.sensitive = false;
        forward_button.sensitive = false;
        home_button.sensitive = false;
        up_button.sensitive = false;
        root_button.sensitive = false;
        address.sensitive = false;
        bookmarks_button.sensitive = false;
    }

    private void enable_buttons () {
        home_button.sensitive = true;
        address.sensitive = true;
        back_button.sensitive = _session.has_back ();
        forward_button.sensitive = _session.has_forward ();
        var is_gemini_site = session.current_uri.scheme == "gemini";
        up_button.sensitive = is_gemini_site;
        root_button.sensitive = is_gemini_site;
        bookmarks_button.sensitive = true;
    }

    private void show_reload_button () {
        stop_reload_button.set_image (reload_icon);
        stop_reload_button.action_name = full_name (Window.ACTION_RELOAD);
        stop_reload_button.tooltip_markup = Granite.markup_accel_tooltip (
            Window.action_accelerators[Window.ACTION_RELOAD].to_array (),
            _("Reload")
        );
    }

    private void show_stop_button () {
        stop_reload_button.set_image (stop_icon);
        stop_reload_button.action_name = full_name (Window.ACTION_STOP);
        stop_reload_button.tooltip_markup = Granite.markup_accel_tooltip (
            Window.action_accelerators[Window.ACTION_STOP].to_array (),
            _("Stop")
        );
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
            primary_icon_activatable = true,
            primary_icon_tooltip_text = _("Check identity"),
            hexpand = true,
            secondary_icon_activatable = true,
            secondary_icon_name = "non-starred",
            secondary_icon_tooltip_text = _("Bookmark this page")
        };

        unowned Gtk.StyleContext style_ctx = address.get_style_context ();
        style_ctx.add_provider (address_style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        address.activate.connect ((a) => {
            window.activate_action (Window.ACTION_RELOAD, null);
        });

        address.icon_release.connect ((pos, event) => {
            if (pos == Gtk.EntryIconPosition.PRIMARY) {
                cert_popover.set_session (session);
                cert_popover.window = window;
                cert_popover.pointing_to = address.get_icon_area (Gtk.EntryIconPosition.PRIMARY);
                cert_popover.show_all ();
            } else if (pos == Gtk.EntryIconPosition.SECONDARY) {
                var manager = _session.bookmarks_manager;
                var uri = _session.current_uri;
                if (manager.is_bookmarked (uri)) {
                    window.activate_action (Window.ACTION_REMOVE_BOOKMARK, null);
                    address.secondary_icon_name = "non-starred";
                    address.secondary_icon_tooltip_text = _("Bookmark this page");
                } else {
                    window.activate_action (Window.ACTION_ADD_BOOKMARK, null);
                    address.secondary_icon_name = "starred";
                    address.secondary_icon_tooltip_text = _("Remove this page rom bookmarks");
                }
            }
        });

        return address;
    }

    private void update_address_bookmark_icon () {
        var manager = _session.bookmarks_manager;
        var uri = _session.current_uri;
        if (manager.is_bookmarked (uri)) {
            address.secondary_icon_name = "starred";
            address.secondary_icon_tooltip_text = _("Remove this page rom bookmarks");
        } else {
            address.secondary_icon_name = "non-starred";
            address.secondary_icon_tooltip_text = _("Bookmark this page");
        }
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

        var intro_button = new Gtk.ModelButton () {
            text = _("Introduction to Gemini")
        };

        intro_button.clicked.connect (() => {
            var intro_file_uri = session.settings.get_value ("introduction");
            var action_args = new Variant.tuple ({
                intro_file_uri,
                new Variant.boolean (true)
            });

            window.activate_action (Window.ACTION_LOAD_URI_IN_NEW_TAB, action_args);
        });

        var menu_grid = new Gtk.Grid () {
            margin_bottom = 3,
            orientation = Gtk.Orientation.VERTICAL,
            width_request = 200
        };

        menu_grid.attach (font_size_grid, 0, 0, 3, 1);
        menu_grid.attach (separator, 0, 1, 3, 1);
        menu_grid.attach (preferences_button, 0, 2, 3);
        menu_grid.attach (intro_button, 0, 3, 3);
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
            focus_on_click = false,
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

    private string? icon_name_for (Core.Session session) {
        var uri = session.current_uri;
        var server_cert = session.cert_info;
        var client_cert = session.client_cert_info;
        if (uri.scheme == "file") {
            return null;
        }

        if (server_cert == null || server_cert.is_not_applicable_to_uri ()) {
            return "security-low";
        }

        if (server_cert.is_inactive () || server_cert.is_expired ()) {
            return "security-medium";
        }

        if (client_cert == null) {
            return "security-high";
        }

        return "avatar-default";
    }
}

