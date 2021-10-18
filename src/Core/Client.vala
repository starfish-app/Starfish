public class Starfish.Core.Client : Object {

    public CertManager cert_manager { get; construct; }
    public int max_redirects { get; construct; }

    public Client (CertManager cert_manager, int max_redirects = 5) {
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
        bool accept_mismatched_cert = false
    ) {
        switch (uri.scheme) {
            case "file":
                return yield load_file (uri, cancel);
            case "gemini":
                return yield load_gemini (uri, cancel, 0, follow_redirects, accept_mismatched_cert);
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

            return new InternalErrorResponse.general_error (null, uri, err.message);
        } catch (Error err) {
            return new InternalErrorResponse.general_error (null, uri, err.message);
        }
    }

    private async Response load_gemini (
        Uri uri,
        Cancellable? cancel,
        int redirect_count = 0,
        bool follow_redirects = true,
        bool accept_mismatched_cert = false,
        bool same_domain_request = false // TODO: send from session!
    ) {
        SocketConnection conn;
        CertError? cert_error = null;
        CertInfo? cert_info = null;
        try {
            var socket_client = new SocketClient () {
                tls = true,
                tls_validation_flags = TlsCertificateFlags.VALIDATE_ALL,
                timeout = 100000000
            };
            socket_client.event.connect ((event, connectable, conn) => {
                if (event == SocketClientEvent.TLS_HANDSHAKING) {
                    var tls_conn = (TlsClientConnection) conn;
                    if (same_domain_request) {
                        var client_cert = cert_manager.get_client_cert_for (uri);
                        if (client_cert != null) {
                            tls_conn.certificate = client_cert;
                        }
                    }

                    tls_conn.accept_certificate.connect ((cert, errors) => {
                        try {
                            cert_info = CertInfo.parse (uri, cert);
                            cert_manager.verify (cert_info, accept_mismatched_cert);
                            return true;
                        } catch (CertError err) {
                            cert_error = err;
                            return false;
                        }
                    });
                } else if (event == SocketClientEvent.TLS_HANDSHAKED && cert_info == null) {
                    var tls_conn = (TlsClientConnection) conn;
                    var cert = tls_conn.peer_certificate;
                    try {
                        cert_info = CertInfo.parse (uri, cert);
                    } catch (CertError err) {
                        warning ("Failed to parse trusted certificate, will report page as untrusted. Error: %s", err.message);
                    }
                }
            });
            conn = yield socket_client.connect_to_uri_async (uri.to_string (), 1965, cancel);
            var request = (uri.to_string () + "\r\n").data;
            yield conn.output_stream.write_async (request, Priority.DEFAULT, cancel);
        } catch (Error err) {
            if (cert_error != null) {
                if (cert_error is CertError.PARSING_ERROR || cert_error is CertError.FINGERPRINTING_ERROR) {
                    return new InternalErrorResponse.server_certificate_invalid (cert_info, uri, cert_error.message);
                } else if (cert_error is CertError.MISMATCH_ERROR) {
                    return new InternalErrorResponse.server_certificate_mismatch (cert_info, uri);
                } else if (cert_error is CertError.INVALID_HOST_ERROR) {
                    return new InternalErrorResponse.server_certificate_not_applicable (cert_info, uri);
                }
            }

            return new InternalErrorResponse.connection_failed (cert_info, uri, err.message);
        }

        string status_line;
        try {
            status_line = yield read_status_line (conn.input_stream, cancel);
        } catch (Error err) {
            return new InternalErrorResponse.status_line_invalid (cert_info, uri, err.message);
        }

        try {
            var resp = new Response (uri, status_line, conn, cert_info);
            if (!resp.is_success) {
                yield conn.close_async (Priority.DEFAULT, cancel);
            }

            if (resp.is_redirect && follow_redirects) {
                var new_uri = Uri.parse (resp.meta, uri);
                if (new_uri.scheme != "gemini") {
                    return new InternalErrorResponse.redirect_to_non_gemini_link (cert_info, uri, new_uri);
                }
                if (redirect_count <= max_redirects) {
                    return yield load_gemini (new_uri, cancel, redirect_count + 1, follow_redirects);
                } else {
                    return new InternalErrorResponse.redirect_limit_reached (cert_info, uri, new_uri);
                }
            }

            return resp;
        } catch (Error err) {
            return new InternalErrorResponse.general_error (cert_info, uri, err.message);
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

