public class Starfish.UI.PageErrorView : PageTextView {

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

        var mime = response.mime ();
        if (mime == null) {
            return true;
        }

        return !mime.is_text;
    }

    public override void display (Core.Response response) {
        var error_body = get_error_body_for (response);
        clear ();
        error_body.foreach_line.begin (display_line, new Cancellable ());
        session.loading = false;
    }

    private Core.TextBody get_error_body_for (Core.Response response) {
        string message = get_error_message_for (response);
        return new Core.TextBody.from_string (message);
    }

    private string get_error_message_for (Core.Response response) {
        if (!response.is_success) {
            return """Gemini request failed.
Status code: %d.
Error message: %s""".printf (
                response.status,
                response.meta ?? "unknown reason"
            );
        }

        var mime = response.mime ();
        if (mime == null) {
            return """Gemini response is invalid.
It is missing MIME type.""";
        }

        if (!mime.is_text) {
            return """Could not display gemini response.
Response is of type %s, and only text types can be displayed.""".printf (
                mime.raw
            );
        }

        assert_not_reached ();
    }
}

