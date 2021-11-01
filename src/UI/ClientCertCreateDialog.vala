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

        grid.attach (new Gtk.Image () {
            gicon = new ThemedIcon ("dialog-information-symbolic"),
            pixel_size = 24,
            tooltip_text = _("It is a good practice to use different identity for each site. Give it a name that reflects the site you are planning to use it with.")
        }, 3, 1);

        var name_validation_msg = new Gtk.Label (null) {
            halign = Gtk.Align.END
        };

        name_validation_msg.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);
        grid.attach (name_validation_msg, 1, 2, 2);

        Gtk.RadioButton? subdomain_button = null;
        if (uri.path != null) {
            grid.attach (new Gtk.Label (_("Use for")) {
                halign = Gtk.Align.END,
                margin_start = 12
            }, 0, 3);

            var subpath_button = new Gtk.RadioButton.with_label (
                null,
                _("requests to pages under %s").printf (uri.to_string ())
            );

            grid.attach (subpath_button, 1, 3, 2);
            grid.attach (new Gtk.Image () {
                gicon = new ThemedIcon ("dialog-information-symbolic"),
                pixel_size = 24,
                tooltip_text = _("While it is a good practice to present identity only to pages under this one, some sites require it on all pages. Notable case of this is Station capsule.")
            }, 3, 3);

            subdomain_button = new Gtk.RadioButton.with_label (
                null,
                _("all requests to %s domain").printf (uri.host)
            );

            subdomain_button.group = subpath_button;
            grid.attach (subdomain_button, 1, 4, 2);
        }

        get_content_area ().add(grid);

        var cancel_button = add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        var create_button = (Gtk.Button) add_button (_("Create"), Gtk.ResponseType.ACCEPT);
        create_button.get_style_context ().add_class (
            Gtk.STYLE_CLASS_SUGGESTED_ACTION
        );

        name_entry.changed.connect (() => {
            var name = name_entry.text;
            if (name == null || name == "") {
                name_entry.secondary_icon_name = "process-error-symbolic";
                name_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);
                name_validation_msg.label = _("Please pick a name.");
                create_button.sensitive = false;
                return;
            }

            var existing_names = repo.existing_certificate_names ();
            if (existing_names.contains (name)) {
                name_entry.secondary_icon_name = "process-error-symbolic";
                name_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);
                name_validation_msg.label = _("Identity named %s already exists. Please pick a unique name.").printf (name);
                create_button.sensitive = false;
                return;
            }

            name_entry.secondary_icon_name = "process-completed-symbolic";
            name_entry.get_style_context ().remove_class (Gtk.STYLE_CLASS_ERROR);
            name_validation_msg.label = null;
            create_button.sensitive = true;
        });

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
                        err_dialog.run ();
                        err_dialog.destroy ();
                    }
                });
            } else {
                destroy ();
            }
        });
    }
}

