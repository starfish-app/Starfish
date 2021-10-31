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

        var certs_list = new ClientCertListBox (repo, uri);
        certs_list.cert_picked.connect ((t, c) => {
            window.activate_action (Window.ACTION_RELOAD, null);
        });

        attach_next_to (certs_list, previous, Gtk.PositionType.BOTTOM, 2, 1);
        previous = certs_list;

        var create_button = new Gtk.Button.from_icon_name ("contact-new-symbolic") {
            label = _("Create New Identity"),
            halign = Gtk.Align.START,
            always_show_image = true
        };

        create_button.clicked.connect (() => create_cert_for (uri));
        attach_next_to (create_button, previous, Gtk.PositionType.BOTTOM, 1, 1);

        show_all ();
        session.loading = false;
    }

    private void create_cert_for (Core.Uri uri) {
        var dialog = new ClientCertCreateDialog (
            manager, repo, uri, window
        );
        dialog.show_all ();
    }
}

