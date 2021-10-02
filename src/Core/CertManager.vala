public class Starfish.Core.CertManager : Object {

    public File parent_dir { get; construct; }
    public File known_certs_file { get; construct; }

    private Gee.Map<string, CertInfo> known_certs = new Gee.HashMap<string, CertInfo> ();

    public CertManager () {
        var config_dir = Environment.get_user_config_dir ();
        Object (
            parent_dir: File.new_build_filename (config_dir, "starfish"),
            known_certs_file: File.new_build_filename (config_dir, "starfish", "known_certs")
        );
    }

    construct {
        try {
            var created_new_file = recreate_missing_known_certs_file ();
            if (!created_new_file) {
                load_known_certs_from_file ();
            }
        } catch (Error err) {
            warning ("Failed to create known certs file, error: %s", err.message);
        }
    }

    public void verify (
        SocketConnectable server_identity,
        TlsCertificate certificate,
        bool accept_expired_cert,
        bool accept_mismatched_cert
    ) throws CertError {
        var cert_info = CertInfo.parse (server_identity, certificate);
        var now = new DateTime.now_utc ();
        var cert_has_expired = now.compare (cert_info.expires_at) > 0;
        if (!accept_expired_cert && cert_has_expired) {
            var unix_expiry = cert_info.expires_at.to_unix ();
            throw new CertError.EXPIRED_ERROR ("%lld".printf (unix_expiry));
        }

        var known_cert = known_certs[cert_info.domain_hash];
        if (known_cert == null) {
            if (!cert_has_expired) {
                known_certs[cert_info.domain_hash] = cert_info;
                try_to_append_to_known_certs_file (cert_info);
            }
            return;
        }

        if (now.compare (known_cert.expires_at) > 0) {
            known_certs[cert_info.domain_hash] = cert_info;
            try_to_rewrite_known_certs_file ();
            return;
        }

        if (cert_info.fingerprint != known_cert.fingerprint) {
            if (!accept_mismatched_cert) {
                var tmpl = _("Certificate for %s does not match previously seen one");
                var msg = tmpl.printf (cert_info.domain);
                throw new CertError.MISMATCH_ERROR (msg);
            }

            known_certs[cert_info.domain_hash] = cert_info;
            try_to_rewrite_known_certs_file ();
            return;
        }
    }

    private void try_to_append_to_known_certs_file (CertInfo cert) {
        try {
            var created_new_file = recreate_missing_known_certs_file ();
            if (created_new_file) {
                return;
            }
        } catch (Error err) {
            warning ("Failed to create known certs file, error: %s", err.message);
            return;
        }

        try {
            var out_stream = known_certs_file.append_to (FileCreateFlags.NONE);
            size_t written;
            var row = cert_info_to_row (cert);
            out_stream.write_all (row.data, out written);
        } catch (Error err) {
            warning ("Failed to append cert info to file, error: %s", err.message);
        }
    }

    private void try_to_rewrite_known_certs_file () {
        try {
            var created_new_file = recreate_missing_known_certs_file ();
            if (created_new_file) {
                return;
            }
        } catch (Error err) {
            warning ("Failed to create known certs file, error: %s", err.message);
            return;
        }

        try {
            var out_stream = known_certs_file.replace (null, false, FileCreateFlags.REPLACE_DESTINATION);
            size_t written;
            var content = known_certs_file_content ();
            out_stream.write_all (content.data, out written);
        } catch (Error err) {
            warning ("Failed to rewrite the known certs file, error: %s", err.message);
        }
    }

    private bool recreate_missing_known_certs_file () throws Error {
        if (!parent_dir.query_exists()) {
            parent_dir.make_directory_with_parents ();
        }

        if (!known_certs_file.query_exists ()) {
            var out_stream = known_certs_file.create (FileCreateFlags.NONE);
            size_t written;
            var content = known_certs_file_content ();
            out_stream.write_all (content.data, out written);
            return true;
        }

        return false;
    }

    private void load_known_certs_from_file () throws Error {
        var in_stream = known_certs_file.read ();
        var data_stream = new DataInputStream (in_stream);
        known_certs.clear ();
        string? row = null;
        do {
            row = data_stream.read_line_utf8 ();
            var cert_info = row_to_cert_info (row);
            if (cert_info != null) {
                known_certs[cert_info.domain_hash] = cert_info;
            }
        } while (row != null);
    }

    private string known_certs_file_content () {
        var builder = new StringBuilder ();
        foreach (var cert in known_certs.values) {
            var row = cert_info_to_row (cert);
            builder.append (row);
        }

        return builder.str;
    }

    private string cert_info_to_row (CertInfo cert) {
        return "%s %lld %s\n".printf (
            cert.domain_hash,
            cert.expires_at.to_unix (),
            cert.fingerprint
        );
    }

    private CertInfo? row_to_cert_info (string? row) {
        if (row == null) {
            return null;
        }

        var sections = row.split (" ");
        if (sections.length != 3) {
            return null;
        }

        var expires_at_unix = int64.parse(sections[1]);
        if (expires_at_unix == 0) {
            warning ("Failed to parse %s as Unix timestamp", sections[1]);
            return null;
        }

        var domain_hash = sections[0];
        var expires_at = new DateTime.from_unix_utc (expires_at_unix);

        var fingerprint = sections[2];
        return new CertInfo (expires_at, fingerprint, domain_hash);
    }
}

