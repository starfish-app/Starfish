public class Starfish.UI.PageStaticErrorView : Gtk.Box, ResponseView {

    public Core.Session session { get; construct; }
    private GemtextView gemtext_view;

    private Templates.Template temp_faliue = new Templates.TempFailure ();
    private Templates.Template connection_failed = new Templates.ConnectionFailed ();
    private Templates.Template invalid_response = new Templates.InvalidResponse ();
    private Templates.Template slow_down = new Templates.SlowDown ();
    private Templates.Template non_gemini_redirect = new Templates.NonGeminiRedirect ();
    private Templates.Template too_many_redirects = new Templates.TooManyRedirects ();
    private Templates.Template not_found = new Templates.NotFound ();
    private Templates.Template gone = new Templates.Gone ();
    private Templates.Template bad_request = new Templates.BadRequest ();
    private Templates.Template unsuported_schema = new Templates.UnsuportedSchema ();
    private Templates.Template perm_faliue = new Templates.PermFailure ();
    private Templates.Template cert_not_applicable = new Templates.CertNotApplicable ();
    private Templates.Template file_access_denied = new Templates.FileAccessDenied ();

    public PageStaticErrorView (Core.Session session) {
        Object (
            session: session,
            spacing: 0,
            orientation: Gtk.Orientation.VERTICAL,
            vexpand: true
        );
    }

    construct {
        gemtext_view = new GemtextView (session.theme, session.current_uri) {
            top_margin = 16,
            left_margin = 24,
            right_margin = 24
        };

        var scrollable = new Gtk.ScrolledWindow (null, null) {
            vexpand = true
        };

        scrollable.add (gemtext_view);
        scrollable.show ();
        add (scrollable);
    }

    public bool can_display (Core.Response response) {
        if (response.is_input) {
            return false;
        }

        if (!response.is_success && !is_recoverable_cert_error (response)) {
            return true;
        }

        return false;
    }

    public void clear () {
        gemtext_view.clear ();
    }

    public void display (Core.Response response) {
        var error_body = get_error_body_for (response);
        clear ();
        error_body.foreach_line.begin (
            (line) => {
                gemtext_view.display_line (line);
            }, new Cancellable (),
            (obj, res) => {
                error_body.foreach_line.end (res);
                session.loading = false;
                response.close ();
            }
        );
    }

    private Core.GeminiBody get_error_body_for (Core.Response response) {
        string content = get_page_content_for (response);
        return new Core.GeminiBody.from_string (content);
    }

    private string get_page_content_for (Core.Response response) {
        switch (response.status) {
            case Core.InternalErrorResponse.CONNECTION_FAILED:
                return connection_failed.render (
                    Templates.ConnectionFailed.URI_KEY, response.uri.to_string (),
                    Templates.ConnectionFailed.DOMAIN_KEY, response.uri.host,
                    Templates.ConnectionFailed.ERROR_MESSAGE_KEY, response.meta
                );
            case Core.InternalErrorResponse.STATUS_LINE_INVALID:
            case Core.InternalErrorResponse.SERVER_CERTIFICATE_INVALID:
                return invalid_response.render (
                    Templates.InvalidResponse.URI_KEY, response.uri.to_string (),
                    Templates.InvalidResponse.ERROR_MESSAGE_KEY, response.meta
                );
            case Core.InternalErrorResponse.REDIRECT_TO_NON_GEMINI_LINK:
                var uri_str = response.meta.strip ();
                string scheme = "unknown";
                try {
                    scheme = Core.Uri.parse (uri_str).scheme;
                } catch (Core.UriError ignored) {}
                return non_gemini_redirect.render (
                    Templates.NonGeminiRedirect.URI_KEY, response.uri.to_string (),
                    Templates.NonGeminiRedirect.REDIRECT_PROTOCOL_KEY, scheme,
                    Templates.NonGeminiRedirect.REDIRECT_URI_KEY, uri_str
                );
            case Core.InternalErrorResponse.REDIRECT_LIMIT_REACHED:
                return too_many_redirects.render (
                    Templates.TooManyRedirects.URI_KEY, response.uri.to_string (),
                    Templates.TooManyRedirects.REDIRECT_URI_KEY, response.meta.strip ()
                );
            case 40:
            case 41:
            case 42:
            case 43:
                return temp_faliue.render (
                    Templates.TempFailure.URI_KEY, response.uri.to_string (),
                    Templates.TempFailure.STATUS_CODE_KEY, "%d".printf (response.status),
                    Templates.TempFailure.META_KEY, response.meta
                );
            case 44:
                return slow_down.render (
                    Templates.SlowDown.URI_KEY, response.uri.to_string (),
                    Templates.SlowDown.SECONDS_TO_WAIT_KEY, response.meta.strip ()
                );
            case Core.InternalErrorResponse.SERVER_CERTIFICATE_NOT_APPLICABLE:
                return cert_not_applicable.render (
                    Templates.CertNotApplicable.URI_KEY, response.uri.to_string (),
                    Templates.CertNotApplicable.HOST_KEY, response.meta
                );
            case 50:
                return perm_faliue.render (
                    Templates.PermFailure.URI_KEY, response.uri.to_string (),
                    Templates.PermFailure.STATUS_CODE_KEY, "%d".printf (response.status),
                    Templates.PermFailure.META_KEY, response.meta
                );
            case Core.InternalErrorResponse.SCHEMA_NOT_SUPPORTED:
                return unsuported_schema.render (
                    Templates.UnsuportedSchema.URI_KEY, response.uri.to_string (),
                    Templates.UnsuportedSchema.PROTOCOL_KEY, response.uri.scheme
                );
            case 51:
                return not_found.render (
                    Templates.NotFound.URI_KEY, response.uri.to_string (),
                    Templates.NotFound.META_KEY, response.meta
                );
            case 52:
                return gone.render (
                    Templates.Gone.URI_KEY, response.uri.to_string (),
                    Templates.Gone.META_KEY, response.meta
                );
            case 53:
            case 59:
                return bad_request.render (
                    Templates.BadRequest.URI_KEY, response.uri.to_string (),
                    Templates.BadRequest.DOMAIN_KEY, response.uri.host,
                    Templates.BadRequest.STATUS_CODE_KEY, "%d".printf (response.status),
                    Templates.BadRequest.META_KEY, response.meta
                );
            case Core.InternalErrorResponse.FILE_ACCESS_DENIED:
                return file_access_denied.render (
                    Templates.FileAccessDenied.PATH_KEY, response.uri.path
                );
            default:
                return temp_faliue.render (
                    Templates.TempFailure.URI_KEY, response.uri.to_string (),
                    Templates.TempFailure.STATUS_CODE_KEY, "%d".printf (response.status),
                    Templates.TempFailure.META_KEY, response.meta
                );
        }
    }

    private bool is_recoverable_cert_error (Core.Response response) {
        return response.status == Core.InternalErrorResponse.SERVER_CERTIFICATE_MISMATCH
            || response.is_client_cert;
    }
}

