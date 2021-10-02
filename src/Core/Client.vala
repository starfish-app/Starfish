public class Starfish.Core.Client : Object {

    public CertManager cert_manager { get; construct; }
    public int max_redirects { get; construct; }

    public Client (int max_redirects = 5, CertManager cert_manager = new CertManager()) {
        Object (
            max_redirects: max_redirects,
            cert_manager: cert_manager
        );
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

    public async Response load (
        Uri uri,
        Cancellable? cancel = null,
        bool follow_redirects = true,
        bool accept_expired_cert = false,
        bool accept_mismatched_cert = false
    ) {
        switch (uri.scheme) {
            case "file":
                return yield load_file (uri, cancel);
            case "gemini":
                return yield load_gemini (uri, cancel, 0, follow_redirects, accept_expired_cert, accept_mismatched_cert);
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

    private async Response load_gemini (
        Uri uri,
        Cancellable? cancel,
        int redirect_count = 0,
        bool follow_redirects = true,
        bool accept_expired_cert = false,
        bool accept_mismatched_cert = false
    ) {
        SocketConnection conn;
        CertError cert_error = null;
        try {
            var socket_client = new SocketClient () {
                tls = true,
                timeout = 100000000
            };
            socket_client.event.connect ((event, connectable, conn) => {
                if (event == SocketClientEvent.TLS_HANDSHAKING) {
                    var tls_conn = (TlsClientConnection) conn;
                    tls_conn.accept_certificate.connect ((cert, errors) => {
                        try {
                            cert_manager.verify (tls_conn.server_identity, cert, accept_expired_cert, accept_mismatched_cert);
                            return true;
                        } catch (CertError err) {
                            cert_error = err;
                            return false;
                        }
                    });
                }
            });
            conn = yield socket_client.connect_to_uri_async (uri.to_string (), 1965, cancel);
            var request = (uri.to_string () + "\r\n").data;
            yield conn.output_stream.write_async (request, Priority.DEFAULT, cancel);
        } catch (Error err) {
            if (cert_error != null) {
                if (cert_error is CertError.PARSING_ERROR || cert_error is CertError.FINGERPRINTING_ERROR) {
                    return new InternalErrorResponse.server_certificate_invalid (uri, cert_error.message);
                } else if (cert_error is CertError.EXPIRED_ERROR) {
                    return new InternalErrorResponse.server_certificate_expired (uri, cert_error.message);
                } else if (cert_error is CertError.MISMATCH_ERROR) {
                    return new InternalErrorResponse.server_certificate_mismatch (uri);
                }
            }

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
                    return yield load_gemini (new_uri, cancel, redirect_count + 1, follow_redirects);
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

