public class Starfish.UI.ClientCertCreateDialog : Granite.Dialog {

    public Core.CertManager manager { get; construct; }
    public Core.ClientCertRepo repo { get; construct; }
    public Core.Uri uri { get; construct; }
    public Window window { get; construct; }

    public ClientCertCreateDialog (
        Core.CertManager manager,
        Core.ClientCertRepo repo,
        Core.Uri uri,
        Window window
    ) {
        Object (
            manager: manager,
            repo: repo,
            uri: uri,
            window: window,
            transient_for: window
        );
    }

    construct {
        var grid = new Gtk.Grid () {
            margin = 12,
            column_spacing = 16,
            row_spacing = 16
        };

        var header = new Granite.HeaderLabel (_("Create identity"));
        grid.attach (header, 0, 0, 3);
        grid.attach (new Gtk.Label (_("Certificate name")) {
            halign = Gtk.Align.END,
            margin_start = 12
        }, 0, 1);

        var name_entry = new Gtk.Entry () {
            hexpand = true,
            text = uri.host
        };

        grid.attach (name_entry, 1, 1, 2);

        Gtk.RadioButton? subdomain_button = null;
        if (uri.path != null) {
            grid.attach (new Gtk.Label (_("Use for")) {
                halign = Gtk.Align.END,
                margin_start = 12
            }, 0, 2);

            var subpath_button = new Gtk.RadioButton.with_label (
                null,
                _("requests to pages under %s").printf (uri.to_string ())
            );

            grid.attach (subpath_button, 1, 2, 2);

            subdomain_button = new Gtk.RadioButton.with_label (
                null,
                _("all requests to %s domain").printf (uri.host)
            );

            subdomain_button.group = subpath_button;
            grid.attach (subdomain_button, 1, 3, 2);
        }

        get_content_area ().add(grid);

        var cancel_button = add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        var create_button = (Gtk.Button) add_button (_("Create"), Gtk.ResponseType.ACCEPT);
        create_button.get_style_context ().add_class (
            Gtk.STYLE_CLASS_SUGGESTED_ACTION
        );

        response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.ACCEPT) {
                name_entry.editable = false;
                cancel_button.sensitive = false;
                create_button.sensitive = false;
                create_button.always_show_image = true;
                var spinner = new Gtk.Spinner ();
                create_button.image = spinner;
                spinner.start ();
                create_button.show_all ();
                var name = name_entry.text;
                manager.create_client_cert.begin (name, (obj, res) => {
                    try {
                        manager.create_client_cert.end (res);
                        if (subdomain_button != null && subdomain_button.active) {
                            var domain_uri = new Core.Uri (uri.scheme, uri.userinfo, uri.host, uri.port);
                            repo.link (domain_uri, name);
                        } else {
                            repo.link (uri, name);
                        }

                        destroy ();
                        window.activate_action (Window.ACTION_RELOAD, null);
                    } catch (Core.CertError error) {
                        destroy ();
                        var err_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                             _("Failed to crete identity"),
                             _("Failed to create client certificate. To proceed you can retry creating identity, or pick an existing one."),
                             "dialog-error",
                             Gtk.ButtonsType.CLOSE
                        );

                        err_dialog.show_error_details (error.message);
                        err_dialog.show_all ();
                    }
                });
            } else {
                destroy ();
            }
        });
    }
}

