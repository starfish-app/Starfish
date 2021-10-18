public class Starfish.Core.CertManager : Object {

    public File config_dir { get; construct; }
    public File known_certs_file { get; construct; }
    public ClientCertFactory cert_factory { get; construct; }
    public ClientCertRepo cert_repo { get; construct; }

    private Gee.Map<string, CertHash> known_certs = new Gee.HashMap<string, CertHash> ();

    public CertManager () {
        var usr_config_dir = Environment.get_user_config_dir ();
        var config_dir = File.new_build_filename (usr_config_dir, "starfish");
        Object (
            config_dir: config_dir,
            known_certs_file: config_dir.get_child ("known_certs"),
            cert_factory: new ClientCertFactory (),
            cert_repo: new ClientCertRepo (config_dir)
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

    public CertInfo verify (
        CertInfo cert_info,
        bool accept_mismatched_cert
    ) throws CertError {
        if (cert_info.is_not_applicable_to_uri ()) {
            throw new CertError.INVALID_HOST_ERROR (
                "TLS certificate is not applicable to requested URI's host."
            );
        }

        var cert_hash = CertHash.from_cert (cert_info);
        var known_cert = known_certs[cert_hash.host_hash];
        if (known_cert == null) {
            if (!cert_info.is_inactive () && !cert_info.is_expired ()) {
                known_certs[cert_hash.host_hash] = cert_hash;
                try_to_append_to_known_certs_file (cert_hash);
            }
            return cert_info;
        }

        var now = new DateTime.now_utc ();
        if (now.compare (known_cert.expires_at) > 0) {
            known_certs[cert_hash.host_hash] = cert_hash;
            try_to_rewrite_known_certs_file ();
            return cert_info;
        }

        if (cert_hash.fingerprint != known_cert.fingerprint) {
            if (!accept_mismatched_cert) {
                var tmpl = _("Certificate for %s does not match previously seen one");
                var msg = tmpl.printf (cert_info.host);
                throw new CertError.MISMATCH_ERROR (msg);
            }

            known_certs[cert_hash.host_hash] = cert_hash;
            try_to_rewrite_known_certs_file ();
            return cert_info;
        }

        return cert_info;
    }

    public TlsCertificate? get_client_cert_for (Uri uri) {
        File? pk_file;
        File? cert_file;
        var found = cert_repo.get_cert_files_for_uri (
            uri,
            out pk_file,
            out cert_file
        );

        if (!found) {
            return null;
        }

        try {
            return new TlsCertificate.from_files (
                cert_file.get_path (),
                pk_file.get_path ()
            );
        } catch (Error error) {
            warning ("Failed to load client cert from files %s and %s, will proceed without it. Error: %s".printf (
                cert_file.get_path (),
                pk_file.get_path (),
                error.message
            ));
            return null;
        }
    }

    private void try_to_append_to_known_certs_file (CertHash cert) {
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
            var row = cert.to_file_row ();
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
        if (!config_dir.query_exists()) {
            config_dir.make_directory_with_parents ();
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
            var cert = CertHash.from_file_row (row);
            if (cert != null) {
                known_certs[cert.host_hash] = cert;
            }
        } while (row != null);
    }

    private string known_certs_file_content () {
        var builder = new StringBuilder ();
        foreach (var cert in known_certs.values) {
            var row = cert.to_file_row ();
            builder.append (row);
        }

        return builder.str;
    }
}

