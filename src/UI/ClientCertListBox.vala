public class Starfish.UI.ClientCertListBox : Gtk.ListBox {

    public Core.ClientCertRepo repo { get; construct; }
    public Window window { get; construct; }
    public Core.Uri uri { get; construct; }

    public ClientCertListBox (
        Core.ClientCertRepo repo,
        Window window,
        Core.Uri uri
    ) {
        Object (
            repo: repo,
            window: window,
            uri: uri,
            activate_on_single_click: false,
            selection_mode: Gtk.SelectionMode.NONE
        );
    }

    construct {

        foreach (var cert_name in repo.existing_certificate_names ()) {
            var row = new Gtk.ListBoxRow () {
                activatable = false,
                selectable = false
            };

            var grid = new Gtk.Grid () {
                orientation = Gtk.Orientation.HORIZONTAL,
                margin_left = 24,
                margin_right = 24,
                column_spacing = 16,
                margin_top = 4,
                margin_bottom = 4
            };

            var label = new Granite.HeaderLabel (cert_name) {
                hexpand = true
            };
            grid.attach (label, 0, 0);
            grid.attach (new Gtk.VSeparator (), 1, 0);

            var use_button = new Gtk.Button.with_label (_("Use"));
            use_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            use_button.tooltip_text = _("Use %s identity for requests to pages under %s.").printf (cert_name, uri.to_string ());
            use_button.clicked.connect (() => {
                repo.link (uri, cert_name);
                window.activate_action (Window.ACTION_RELOAD, null);
            });
            grid.attach (use_button, 2, 0);

            var use_for_domain_button = new Gtk.Button.with_label (_("Use For Domain"));
            use_for_domain_button.tooltip_text = _("Use %s identity for all requests to %s domain. This might be required for some gempods, such as station.").printf (cert_name, uri.host);
            use_for_domain_button.clicked.connect (() => {
                var domain_uri = new Core.Uri (uri.scheme, uri.userinfo, uri.host);
                repo.link (domain_uri, cert_name);
                window.activate_action (Window.ACTION_RELOAD, null);
            });
            grid.attach (use_for_domain_button, 3, 0);

            grid.attach (new Gtk.VSeparator (), 4, 0);
            var delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
                label = _("Delete"),
                always_show_image = true
            };
            delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            grid.attach (delete_button, 5, 0);
            row.add (grid);
            add (row);
        }

        show_all ();
    }

}
