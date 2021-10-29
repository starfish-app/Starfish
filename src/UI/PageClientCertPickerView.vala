public class Starfish.UI.PageClientCertPickerView : Gtk.Grid, ResponseView {

    public Core.Session session { get; construct; }
    public Core.ClientCertRepo repo { get; construct; }
    public Core.CertManager manager { get; construct; }
    public Window window { get; construct; }

    public PageClientCertPickerView (Core.Session session, Window window) {
        Object (
            session: session,
            repo: session.client_cert_repo,
            manager: session.cert_manager,
            window: window,
            orientation: Gtk.Orientation.VERTICAL,
            margin_top: 16,
            margin_left: 24,
            margin_right: 24,
            row_spacing: 16,
            column_spacing: 8
        );
    }

    public bool can_display (Core.Response response) {
        return response.is_client_cert;
    }

    public void clear () {
        foreach (var child in get_children ()) {
            remove (child);
        }
    }

    public void display (Core.Response response) {
        var uri = response.uri;

        var heading = new Gtk.Label (_("Client identification required")) {
            halign = Gtk.Align.START,
            wrap = true,
            selectable = true,
        };

        heading.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        attach (heading, 0, 1, 2, 1);

        var desc = new Gtk.Label (_("   The page at %s requires you to use a client certificate to identify yourself. This is usually reuired in order for the pod to show you some personalized content. For example by using the same certificate as last time you accessed this pod you may be able to pick up where you left off or your saved prefferences may be applied. Alternativelly, if you want to present a new identity to the server you can generate and use a new client certifcate.").printf (uri.to_string ())) {
            halign = Gtk.Align.START,
            wrap = true,
            selectable = true,
        };

        attach_next_to (desc, heading, Gtk.PositionType.BOTTOM, 2, 1);
        Gtk.Widget previous = desc;

        var certs_list = new ClientCertListBox (repo, window, uri);
        attach_next_to (certs_list, previous, Gtk.PositionType.BOTTOM, 2, 1);
        previous = certs_list;

        var create_button = new Gtk.Button.with_label (_("Create new identity")) {
            halign = Gtk.Align.START
        };

        create_button.clicked.connect (() => create_cert_for (uri));
        attach_next_to (create_button, previous, Gtk.PositionType.BOTTOM, 1, 1);

        show_all ();
        session.loading = false;
    }

    private void create_cert_for (Core.Uri uri) {
        var header = new Granite.HeaderLabel (_("Create identity"));
        var desc = new Gtk.Label (_("Pick a name for this identity."));
        var name_entry = new Gtk.Entry ();
        var layout = new Gtk.Grid () {
            row_spacing = 12,
            margin = 16
        };

        layout.attach (header, 0, 1);
        layout.attach (desc, 0, 2);
        layout.attach (name_entry, 0, 3);
        var dialog = new Granite.Dialog () {
            transient_for = window,
        };

        dialog.get_content_area ().add(layout);
        var cancel_button = dialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        var create_button = dialog.add_button (_("Create"), Gtk.ResponseType.ACCEPT);
        create_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        dialog.show_all ();
        dialog.response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.ACCEPT) {
                cancel_button.sensitive = false;
                create_button.sensitive = false;
                name_entry.editable = false;
                var name = name_entry.text;
                manager.create_client_cert.begin (name, (obj, res) => {
                    try {
                        manager.create_client_cert.end (res);
                        repo.link (uri, name);
                        dialog.destroy ();
                        window.activate_action (Window.ACTION_RELOAD, null);
                    } catch (Core.CertError error) {
                        dialog.destroy ();
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
                dialog.destroy ();
            }
        });
    }
}

