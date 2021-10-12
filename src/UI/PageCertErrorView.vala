public class Starfish.UI.PageCertErrorView : Gtk.Grid, ResponseView {

    public Core.Session session { get; construct; }

    private Gtk.Label title;
    private Gtk.Label descritpion;
    private Gtk.Button back_button;
    private Gtk.Button allow_button;

    public PageCertErrorView (Core.Session session) {
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

        title = new Gtk.Label (null) {
            halign = Gtk.Align.START
        };

        title.set_markup (_("<span variant=\"smallcaps\" size=\"xx-large\">Received an invalid certificate</span>"));
        attach (title, 0, 0, 2);

        descritpion = new Gtk.Label (null) {
            halign = Gtk.Align.START,
            wrap = true
        };

        attach (descritpion, 0, 1, 2);

        back_button = new Gtk.Button.with_label (_("Go back")) {
            halign = Gtk.Align.START
        };

        back_button.clicked.connect (session.navigate_back);
        attach (back_button, 0, 2);

        allow_button = new Gtk.Button () {
            halign = Gtk.Align.END
        };

        attach_next_to (allow_button, back_button, Gtk.PositionType.RIGHT);
    }

    public bool can_display (Core.Response response) {
        return response.status == Core.InternalErrorResponse.SERVER_CERTIFICATE_EXPIRED
            || response.status == Core.InternalErrorResponse.SERVER_CERTIFICATE_MISMATCH;
    }

    public void clear () {
        descritpion.label = null;
        allow_button.label = null;
    }

    public void display (Core.Response response) {
        var host = response.uri.host;
        string desc = _("<span>Certificate for %s appears to be invalid. To proceed you can:</span>").printf (host);
        switch (response.status) {
            case Core.InternalErrorResponse.SERVER_CERTIFICATE_EXPIRED:
                var expires_at_unix = int64.parse(response.meta);
                allow_button.label = _("Load the page anyway");
                allow_button.clicked.connect (() => {
                    session.navigate_to (session.current_uri.to_string (), true);
                });

                if (expires_at_unix == 0) {
                    warning ("Failed to parse %s as Unix timestamp", response.meta);
                    desc = _("<span>Certificate for %s has expired. To proceed you can:</span>").printf (host);
                    break;
                }

                var expired_at = new DateTime.from_unix_utc (expires_at_unix);
                desc = _("<span>Certificate for %s has expired at %s. To proceed you can:</span>").printf (host, expired_at.format ("%X %d-%m-%Y"));
                break;
            case Core.InternalErrorResponse.SERVER_CERTIFICATE_MISMATCH:
                allow_button.label = _("Trust the new certificate");
                allow_button.clicked.connect (() => {
                    session.navigate_to (session.current_uri.to_string (), false, true);
                });

                desc = _("<span>Certificate for %s has changed since last time you wisited it. To proceed you can:</span>").printf (host);
                break;
        }

        descritpion.set_markup (desc);
        session.loading = false;
    }
}

