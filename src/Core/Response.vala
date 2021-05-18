public class Starfish.Core.Response : Object {

    public Uri uri { get; construct; }
    public string raw_status_line { private get; construct; }
    public IOStream connection { get; construct; }

    public int status { get; private set; default = -1; }
    public string? meta { get; private set; default = "Unsupported server response."; }

    public bool is_unsupported_server_response { get { return status < 10; } }
    public bool is_input { get { return status >= 10 && status < 20; } }
    public bool is_success { get { return status >= 20 && status < 30; } }
    public bool is_redirect { get { return status >= 30 && status < 40; } }
    public bool is_temp_fail { get { return status >= 40 && status < 50; } }
    public bool is_perm_fail { get { return status >= 50 && status < 60; } }
    public bool is_fail { get { return is_temp_fail || is_perm_fail; } }
    public bool is_client_cert { get { return status >= 60 && status < 70; } }

    public Response (Uri uri, string status_line, owned IOStream connection) {
        Object (
            uri: uri,
            raw_status_line: status_line,
            connection: connection
        );
    }

    construct {
        if (raw_status_line == null) {
            return;
        }

        var segments = raw_status_line.strip ().split (" ", 2);
        if (segments.length < 1) {
            return;
        }

        int parsed_status;
        var valid_status = int.try_parse(segments[0], out parsed_status);
        if (!valid_status || parsed_status >= 70) {
            return;
        }

        status = parsed_status;
        if (segments.length == 2) {
            meta = segments[1];
        } else {
            meta = null;
        }
    }

    public Mime? mime () {
        if (meta == null) {
            return null;
        }

        return new Mime (meta);
    }

    public TextBody? text_body () {
        var mime = mime ();
        if (mime == null) {
            return null;
        }

        if (mime.is_gemtext) {
            return new GeminiBody (mime, connection);
        }

        if (mime.is_text) {
            return new TextBody (mime, connection);
        }

        return null;
    }

    public void close () {
        try_to_close.begin ();
    }

    private async void try_to_close () {
        try {
            yield connection.close_async (Priority.DEFAULT);
        } catch (IOError e) {
            warning ("Could not close connection, might leak resources! Error: %s", e.message);
        }
    }
}

