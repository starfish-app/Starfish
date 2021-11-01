public class Starfish.UI.ClientCertListBox : Gtk.ListBox {

    public Core.ClientCertRepo repo { get; construct; }
    public Core.Uri uri { get; construct; }
    public string? linked_host { get; construct; }
    public bool show_extra_actions { get; construct; }

    public signal void cert_picked (string cert);

    public ClientCertListBox (
        Core.ClientCertRepo repo,
        Core.Uri uri,
        bool show_only_linked_host = false,
        bool show_extra_actions = true
    ) {
        string? linked_host = null;
        if (show_only_linked_host) {
            linked_host = uri.host;
        }

        Object (
            repo: repo,
            uri: uri,
            linked_host: linked_host,
            show_extra_actions: show_extra_actions,
            activate_on_single_click: false,
            selection_mode: Gtk.SelectionMode.NONE
        );
    }

    construct {
        foreach (var cert_name in repo.existing_certificate_names (linked_host)) {
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
            grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 1, 0);

            var use_button = new Gtk.Button.with_label (_("Use"));
            use_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            use_button.tooltip_text = _("Use %s identity for requests to pages under %s.").printf (cert_name, uri.to_string ());
            use_button.clicked.connect (() => {
                repo.link (uri, cert_name);
                cert_picked (cert_name);
            });
            grid.attach (use_button, 2, 0);

            var use_for_domain_button = new Gtk.Button.with_label (_("Use For Domain"));
            use_for_domain_button.tooltip_text = _("Use %s identity for all requests to %s domain. This might be required for some gempods, such as station.").printf (cert_name, uri.host);
            use_for_domain_button.clicked.connect (() => {
                var domain_uri = new Core.Uri (uri.scheme, uri.userinfo, uri.host);
                repo.link (domain_uri, cert_name);
                cert_picked (cert_name);
            });
            grid.attach (use_for_domain_button, 3, 0);

            if (show_extra_actions) {
                grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 4, 0);
                var dir_button = new Gtk.Button.from_icon_name ("folder-open") {
                    tooltip_text = _("Show certificate and private key files for %s").printf (cert_name),
                    focus_on_click = false
                };

                dir_button.clicked.connect (() => {
                    var cert_dir = repo.find_cert_dir_for (cert_name);
                    try {
                        Gtk.show_uri_on_window (null, cert_dir, (uint32) Gdk.CURRENT_TIME);
                    } catch (Error error) {
                        warning ("Failed to open cert directory %s, will skip operation. Error message: %s".printf (cert_dir, error.message));
                    }
                });


                grid.attach (dir_button, 5, 0);

                var delete_button = new Gtk.Button.from_icon_name ("user-trash") {
                    tooltip_text = _("Stop using %s identity and send its files to trash").printf (cert_name),
                    focus_on_click = false
                };

                delete_button.clicked.connect (() => {
                    repo.delete_cert (cert_name);
                    remove (row);
                });

                grid.attach (delete_button, 6, 0);
            }

            row.add (grid);
            add (row);
        }

        show_all ();
    }

}
