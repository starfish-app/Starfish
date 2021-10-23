public class Starfish.Core.ClientCertRepo : Object {

    public File root_cert_dir { get; construct; }
    public File certs_file { get; construct; }
    public Gee.Map<string, string> uri_to_cert { get; construct; }

    public ClientCertRepo (File root_dir) {
        var dir = File.new_build_filename (root_dir.get_path (), "certificates");
        Object (
            root_cert_dir: dir,
            certs_file: File.new_build_filename (dir.get_path (), "certs"),
            uri_to_cert: new Gee.HashMap<string, string> ()
        );
    }

    construct {
        try {
            recreate_missing_certs_dir ();
            load_uri_to_cert_map ();
        } catch (Error err) {
            warning ("Failed to create certs directory structure, error: %s".printf (err.message));
        }
    }

    // Can throw CLIENT_CERT_GENERATION_ERROR
    public void set_up_new_cert_files (
        string name,
        out File private_key_file,
        out File certificate_file
    ) throws CertError {
        var dir = root_cert_dir.get_child (name);
        try {
            dir.make_directory_with_parents ();
        } catch (Error err) {
            if (!(err is IOError.EXISTS)) {
                throw new CertError.CLIENT_CERT_GENERATION_ERROR (
                    "Failed to crate client certificate directory %s, error: %s.".printf (dir.get_path (), err.message)
                );
            }
        }

        private_key_file = dir.get_child ("pk.pem");
        try {
            private_key_file.create (FileCreateFlags.NONE);
        } catch (Error err) {
            if (!(err is IOError.EXISTS)) {
                throw new CertError.CLIENT_CERT_GENERATION_ERROR (
                    "Failed to crate private key file %s, error: %s.".printf (private_key_file.get_path (), err.message)
                );
            }
        }

        certificate_file = dir.get_child ("cert.pem");
        try {
            certificate_file.create (FileCreateFlags.NONE);
        } catch (Error err) {
            if (!(err is IOError.EXISTS)) {
                throw new CertError.CLIENT_CERT_GENERATION_ERROR (
                    "Failed to crate private key file %s, error: %s.".printf (certificate_file.get_path (), err.message)
                );
            }
        }
    }

    public void link (Uri uri, string cert_name) {
        var str_uri = uri.to_string ();
        if (uri_to_cert[str_uri] == cert_name) {
            return;
        }
        uri_to_cert[str_uri] = cert_name;
        var row = create_row (str_uri, cert_name);
        try_to_append_to_certs.begin (row);
    }

    public void unlink (Uri uri, string cert_name) {
        string? key_to_remove = null;
        foreach (var entry in uri_to_cert.entries) {
            try {
                var key_uri = Uri.parse (entry.key);
                if (uri.is_subresource_of (key_uri) && entry.value == cert_name) {
                    key_to_remove = entry.key;
                    break;
                }
            } catch (UriError ignored) {
                continue;
            }
        }

        if (key_to_remove != null) {
            uri_to_cert.unset (key_to_remove);
            try_to_recreate_certs_file.begin ();
        }
    }

    public bool get_cert_files_for_uri (
        Uri uri,
        out File? private_key_file,
        out File? certificate_file
    ) {
        var str_uri = uri.to_string ();
        string? cert_name = null;
        foreach (var entry in uri_to_cert.entries) {
            if (str_uri.has_prefix (entry.key)) {
                cert_name = entry.value;
                break;
            }
        }
        if (cert_name == null) {
            private_key_file = null;
            certificate_file = null;
            return false;
        }

        if (!cert_exists (cert_name)) {
            private_key_file = null;
            certificate_file = null;
            return false;
        }

        var dir = root_cert_dir.get_child (cert_name);
        private_key_file = dir.get_child ("pk.pem");
        certificate_file = dir.get_child ("cert.pem");
        return true;
    }

    public Gee.Collection<string> existing_certificate_names () {
        var names = new Gee.HashSet<string> ();
        var iter = root_cert_dir.enumerate_children (
            FileAttribute.STANDARD_NAME,
            FileQueryInfoFlags.NONE
        );

        FileInfo file_info;
        while ((file_info = iter.next_file ()) != null) {
            var cert_name_candidate = file_info.get_name ();
            if (cert_exists (cert_name_candidate)) {
                names.add (cert_name_candidate);
            }
        }


        return names;
    }

    private void recreate_missing_certs_dir () throws Error {
        if (!root_cert_dir.query_exists ()) {
            root_cert_dir.make_directory_with_parents ();
        }

        if (!certs_file.query_exists ()) {
            certs_file.create (FileCreateFlags.NONE);
        }
    }

    private void load_uri_to_cert_map () throws Error {
        var in_stream = certs_file.read ();
        var data_stream = new DataInputStream (in_stream);
        uri_to_cert.clear ();
        string? row = null;
        while (true) {
            row = data_stream.read_line_utf8 ();
            if (row == null) {
                break;
            }

            var sections = row.split (" ");
            var uri = sections[0];
            var cert_name = sections[1];
            if (cert_exists (cert_name)) {
                uri_to_cert[uri] = cert_name;
            }
        }
    }

    private bool cert_exists (string cert_name) {
        var dir = root_cert_dir.get_child (cert_name);
        if (!dir.query_exists ()) {
            return false;
        }

        if (dir.query_file_type (FileQueryInfoFlags.NONE) != FileType.DIRECTORY) {
            return false;
        }

        var pk = dir.get_child ("pk.pem");
        if (!pk.query_exists ()) {
            return false;
        }

        if (pk.query_file_type (FileQueryInfoFlags.NONE) != FileType.REGULAR) {
            return false;
        }

        var cert = dir.get_child ("cert.pem");
        if (!cert.query_exists ()) {
            return false;
        }

        if (cert.query_file_type (FileQueryInfoFlags.NONE) != FileType.REGULAR) {
            return false;
        }

        return true;
    }

    private async void try_to_append_to_certs (string row) {
        try {
            recreate_missing_certs_dir ();
            var out_stream = yield certs_file.append_to_async (
                FileCreateFlags.NONE,
                Priority.DEFAULT
            );

            size_t written_len;
            var ok = yield out_stream.write_all_async (
                row.data,
                Priority.DEFAULT,
                null,
                out written_len
            );

            if (!ok) {
                warning ("Failed to append %s to certs file %s.".printf (row, certs_file.get_path ()));
            }
        } catch (Error err) {
            warning ("Failed to append %s to certs file %s, error: %s".printf (row, certs_file.get_path (), err.message));
        }
    }

    private async void try_to_recreate_certs_file () {
        var builder = new StringBuilder ();
        foreach (var entry in uri_to_cert.entries) {
            builder.append (create_row (entry.key, entry.value));
        }

        var content = builder.str;
        try {
            recreate_missing_certs_dir ();
            var out_stream = yield certs_file.replace_async (
                null,
                false,
                FileCreateFlags.NONE
            );

            size_t written_len;
            var ok = yield out_stream.write_all_async (
                content.data,
                Priority.DEFAULT,
                null,
                out written_len
            );

            if (!ok) {
                warning ("Failed to rewrite certs file %s.".printf (certs_file.get_path ()));
            }
        } catch (Error err) {
            warning ("Failed to rewrite certs file %s, error: %s".printf (certs_file.get_path (), err.message));
        }
    }

    private string create_row (string uri, string cert_name) {
        return "%s %s\n".printf (uri.to_string (), cert_name);
    }
}

