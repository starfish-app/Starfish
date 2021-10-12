public class Starfish.UI.PageClientCertPickerView : Gtk.Grid, ResponseView {

    public Core.Session session { get; construct; }

    private Gtk.Label descritpion;

    public PageClientCertPickerView (Core.Session session) {
        Object (
            session: session,
            orientation: Gtk.Orientation.VERTICAL,
            margin_top: 16,
            margin_left: 24,
            margin_right: 24,
            row_spacing: 16,
            column_spacing: 8
        );
    }

    construct {
        get_style_context ().add_provider (
            session.theme.get_gemtext_css(),
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        session.theme.notify.connect (() => {
            get_style_context ().add_provider (
                session.theme.get_gemtext_css(),
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        });

        var title = new Gtk.Label (null) {
            halign = Gtk.Align.START,
            wrap_mode = Pango.WrapMode.CHAR
        };

        title.set_markup (_("<span variant=\"smallcaps\" size=\"xx-large\">Client certificate required</span>"));
        attach (title, 0, 0, 2);

        descritpion = new Gtk.Label (null) {
            halign = Gtk.Align.START,
            wrap = true
        };

        attach (descritpion, 0, 1, 2);

        var pick_cert_button = new Gtk.Button.with_label (_("Pick existing certificate")) {
            halign = Gtk.Align.START
        };

        pick_cert_button.clicked.connect (on_pick_certificate);
        attach (pick_cert_button, 0, 2);

        var create_cert_button = new Gtk.Button.with_label (_("Create a new certificate")) {
            halign = Gtk.Align.END
        };
        create_cert_button.clicked.connect (on_create_certificate);

        attach_next_to (create_cert_button, pick_cert_button, Gtk.PositionType.RIGHT);
    }

    public bool can_display (Core.Response response) {
        return response.is_client_cert;
    }

    public void clear () {
        descritpion.label = null;
    }

    public void display (Core.Response response) {
        var uri = response.uri.to_string ();
        switch (response.status) {
            case 60:
                descritpion.label = _("The page at %s requires the use of client certificate. This is usually required in order for server to show you some personalized content. To proceed you can:".printf (uri));
                break;
            case 61:
                descritpion.label = _("The certificate you provided is not authorised to access the page at %s. This page may belong to another user, or you may need to provide a different certificate. To proceed you can:".printf (uri));
                break;
            case 62:
                var theme_color = session.theme.block_background_color;
                var pango_color = "#%x%x%x%x".printf (
                    (int) theme_color.red,
                    (int) theme_color.green,
                    (int) theme_color.blue,
                    (int) (theme_color.alpha*65536)
                );

                descritpion.set_markup(_("<span>The certificate you provided is not valid. This usually happens when certificate's expiry date passes. Alternativelly, the certificate might be wrongly formated.</span> bgcolor=\"%s\">\n\n<tt>\nGemini response details\n\nSTATUS: 62\n\nMETA: %s\n</tt>".printf (pango_color, response.meta)));
                break;
            default:
                break;
        }

        session.loading = false;
    }

    private void on_pick_certificate () {
        // TODO: implement!
        warning ("Should open a dialog for selecting an existing client certificate!");
    }

    private void on_create_certificate () {
        try {
            // TODO: implement!
        } catch (Core.CertError err) {
            error ("Failed to create client certificate, error: %s", err.message);
        }
    }
}

