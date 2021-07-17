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

    public async Response load (Uri uri, Cancellable? cancel = null, bool follow_redirects = true) {
        return yield load_redirected(uri, cancel, follow_redirects);
    }

    private async Response load_redirected (Uri uri, Cancellable? cancel, bool follow_redirects = true, int redirect_count = 0) {
        try {
            var conn = yield socket_client.connect_to_uri_async (uri.to_string (), 1965, cancel);
            var request = (uri.to_string () + "\r\n").data;
            yield conn.output_stream.write_async (request, Priority.DEFAULT, cancel);
            var status_line = yield read_status_line (conn.input_stream, cancel);
            var resp = new Response (uri, status_line, conn);
            if (!resp.is_success) {
                yield conn.close_async (Priority.DEFAULT, cancel);
            }

            if (resp.is_redirect && follow_redirects) {
                var new_uri = Uri.parse (resp.meta, uri);
                if (new_uri.scheme != "gemini") {
                    return new Response (uri, "-1 Received a redirect to non Gemini protocol. If you wish you can manually visit %s.".printf (new_uri.to_string ()), conn);
                }
                if (redirect_count <= max_redirects) {
                    return yield load_redirected (new_uri, cancel, follow_redirects, redirect_count + 1);
                } else {
                    return new Response (uri, "-1 Reached maximum number of redirects. If you wish you can manually visit %s to continue following redirects.".printf (new_uri.to_string ()), conn);
                }
            }

            return resp;
        } catch (Error e) {
            return error_response_for (e.message, uri);
        }
    }

    private async string read_status_line (InputStream input, Cancellable? cancel) {
        var line = new uint8[2 + 1 + 1024 + 2];
        var i = 0;
        var buff = new uint8[1];
        var read_cr = false;
        var read_lf = false;
        try {
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
        } catch (Error e) {
            warning ("Failed to read status line, loading page will fail. Error: %s".printf (e.message));
            return "-1 Failed to read status line";
        }
    }

    private Response error_response_for (string error_message, Uri uri) {
        var in_mem_in = new MemoryInputStream.from_data("".data);
        var in_mem_out = new MemoryOutputStream.resizable ();
        var in_mem_conn = new SimpleIOStream (in_mem_in, in_mem_out);
        return new Response (uri, "-1 Loading %s failed with error: %s.".printf (uri.to_string (), error_message), in_mem_conn);
    }

}

