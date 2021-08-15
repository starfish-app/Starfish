public class Starfish.UI.PageErrorView : PageTextView {

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
    private Templates.Template cert_error = new Templates.CertError ();
    private Templates.Template file_access_denied = new Templates.FileAccessDenied ();

    public PageErrorView (Core.Session session) {
        base (session);
    }

    public override bool can_display (Core.Response response) {
        if (response.is_input) {
            return false;
        }

        if (!response.is_success) {
            return true;
        }

        return false;
    }

    public override void display (Core.Response response) {
        var error_body = get_error_body_for (response);
        clear ();
        error_body.foreach_line.begin (display_line, new Cancellable ());
        session.loading = false;
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
                return invalid_response.render (
                    Templates.InvalidResponse.URI_KEY, response.uri.to_string (),
                    Templates.InvalidResponse.ERROR_MESSAGE_KEY, response.meta
                );
            case Core.InternalErrorResponse.REDIRECT_TO_NON_GEMINI_LINK:
                var redirect_uri = Core.Uri.parse (response.meta.strip ());
                return non_gemini_redirect.render (
                    Templates.NonGeminiRedirect.URI_KEY, response.uri.to_string (),
                    Templates.NonGeminiRedirect.REDIRECT_PROTOCOL_KEY, redirect_uri.scheme,
                    Templates.NonGeminiRedirect.REDIRECT_URI_KEY, redirect_uri.to_string ()
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
            case 60:
            case 61:
            case 62:
                return cert_error.render (
                    Templates.CertError.URI_KEY, response.uri.to_string (),
                    Templates.CertError.STATUS_CODE_KEY, "%d".printf (response.status),
                    Templates.CertError.META_KEY, response.meta
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
}

