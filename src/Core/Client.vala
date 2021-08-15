public class Starfish.Core.Client : Object {

    private SocketClient socket_client;
    public int max_redirects { get; construct; }

    public Client (int max_redirects = 5) {
        Object (max_redirects: max_redirects);
    }

    construct {
        socket_client = new SocketClient () {
            tls = true,
            tls_validation_flags = TlsCertificateFlags.GENERIC_ERROR,
            timeout = 100000000
        };
    }

    public async bool supports (Uri uri, Cancellable? cancel = null) {
        if (uri.scheme == "gemini") {
            return true;
        }

        if (uri.scheme == "file") {
            var file = File.new_for_uri (uri.to_string ());
            try {
                var file_info = yield file.query_info_async (
                    "standard::*",
                    FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                    Priority.DEFAULT,
                    cancel
                );

                return file_info.get_file_type () == FileType.REGULAR;
            } catch (Error err) {
                warning ("Failed to get type of %s, will mark it as non-supported. Error: %s", uri.to_string (), err.message);
            }
        }

        return false;
    }

    public async Response load (Uri uri, Cancellable? cancel = null, bool follow_redirects = true) {
        switch (uri.scheme) {
            case "file":
                return yield load_file (uri, cancel);
            case "gemini":
                return yield load_gemini (uri, cancel, follow_redirects);
        }
        return new InternalErrorResponse.schema_not_supported (uri);
    }

    private async Response load_file (Uri uri, Cancellable? cancel) {
        try {
            var file = File.new_for_uri (uri.to_string ());
            var exists = file.query_exists (cancel);
            if (!exists) {
                return new Response.not_found (uri);
            }

            var file_info = yield file.query_info_async (
                "standard::*",
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                Priority.DEFAULT,
                cancel
            );

            var content_type = file_info.get_content_type ();
            var mime = ContentType.get_mime_type (content_type);
            var file_in = yield file.read_async (Priority.DEFAULT, cancel);
            var mock_out = new MemoryOutputStream.resizable ();
            var io = new SimpleIOStream (file_in, mock_out);
            return new Response (uri, "20 %s".printf (mime), io);
        } catch (IOError err) {
            if (err is IOError.PERMISSION_DENIED) {
                return new InternalErrorResponse.file_access_denied (uri);
            }

            return new InternalErrorResponse.general_error (uri, err.message);
        } catch (Error err) {
            return new InternalErrorResponse.general_error (uri, err.message);
        }
    }

    private async Response load_gemini (Uri uri, Cancellable? cancel, bool follow_redirects = true, int redirect_count = 0) {
        SocketConnection conn;
        try {
            conn = yield socket_client.connect_to_uri_async (uri.to_string (), 1965, cancel);
            var request = (uri.to_string () + "\r\n").data;
            yield conn.output_stream.write_async (request, Priority.DEFAULT, cancel);
        } catch (Error err) {
            return new InternalErrorResponse.connection_failed (uri, err.message);
        }

        string status_line;
        try {
            status_line = yield read_status_line (conn.input_stream, cancel);
        } catch (Error err) {
            return new InternalErrorResponse.status_line_invalid (uri, err.message);
        }

        try {
            var resp = new Response (uri, status_line, conn);
            if (!resp.is_success) {
                yield conn.close_async (Priority.DEFAULT, cancel);
            }

            if (resp.is_redirect && follow_redirects) {
                var new_uri = Uri.parse (resp.meta, uri);
                if (new_uri.scheme != "gemini") {
                    return new InternalErrorResponse.redirect_to_non_gemini_link (uri, new_uri);
                }
                if (redirect_count <= max_redirects) {
                    return yield load_gemini (new_uri, cancel, follow_redirects, redirect_count + 1);
                } else {
                    return new InternalErrorResponse.redirect_limit_reached (uri, new_uri);
                }
            }

            return resp;
        } catch (Error err) {
            return new InternalErrorResponse.general_error (uri, err.message);
        }
    }

    private async string read_status_line (InputStream input, Cancellable? cancel) throws Error {
        var line = new uint8[2 + 1 + 1024 + 2];
        var i = 0;
        var buff = new uint8[1];
        var read_cr = false;
        var read_lf = false;
        while (read_cr == false || read_lf == false) {
            yield input.read_async (buff, Priority.DEFAULT, cancel);
            if (buff[0] == 13) {
                read_cr = true;
            } else if (buff[0] == 10) {
                read_lf = true;
            } else {
                line[i++] = buff[0];
                read_cr = false;
                read_lf = false;
            }
        }
        return (string) line;
    }
}

