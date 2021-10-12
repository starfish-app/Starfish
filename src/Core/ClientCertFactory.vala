public class Starfish.Core.ClientCertFactory : Object {

    // Can throw CLIENT_CERT_GENERATION_ERROR
    public async void create_new_client_cert (
        string name,
        File private_key_file,
        File cert_file,
        Cancellable? cancel = null
    ) throws CertError {
        var pk = generate_private_key ();
        var pk_pem = export_private_key (pk);
        yield write_to_file (pk_pem, private_key_file, cancel);
        var cert = generate_certificate (pk, name);
        var cert_pem = export_certificate (cert);
        yield write_to_file (cert_pem, cert_file, cancel);
    }

    private GnuTLS.X509.PrivateKey generate_private_key () throws CertError {
        var pk = GnuTLS.X509.PrivateKey.create ();
        var res_code = pk.generate (GnuTLS.PKAlgorithm.RSA, 2048, 0);
        if (res_code != GnuTLS.ErrorCode.SUCCESS) {
            throw new CertError.CLIENT_CERT_GENERATION_ERROR (
                "Error generating private key, GnuTLS returned status code %d.".printf (res_code)
            );
        }

        return pk;
    }

    private uint8[] export_private_key (
        GnuTLS.X509.PrivateKey private_key
    ) throws CertError {
        uint8[] buff = new uint8[10000];
        size_t buff_len = buff.length;
        var res_code = private_key.export (
            GnuTLS.X509.CertificateFormat.PEM,
            buff,
            ref buff_len
        );

        if (res_code != GnuTLS.ErrorCode.SUCCESS) {
            throw new CertError.CLIENT_CERT_GENERATION_ERROR (
                "Error exporting private key, GnuTLS returned status code %d.".printf (res_code)
            );
        }

        return buff[0:buff_len];
    }

    private GnuTLS.X509.Certificate generate_certificate (
        GnuTLS.X509.PrivateKey private_key,
        string common_name
    ) throws CertError {
        var cert = GnuTLS.X509.Certificate.create ();
        var res_code = cert.set_key (private_key);
        if (res_code != GnuTLS.ErrorCode.SUCCESS) {
            throw new CertError.CLIENT_CERT_GENERATION_ERROR (
                "Error setting private key on client cert, GnuTLS returned status code %d.".printf (res_code)
            );
        }

        var start_time = new DateTime.now_utc ();
        res_code = cert.set_activation_time ((time_t) start_time.to_unix ());
        if (res_code != GnuTLS.ErrorCode.SUCCESS) {
            throw new CertError.CLIENT_CERT_GENERATION_ERROR (
                "Error setting expiration time on client cert, GnuTLS returned status code %d.".printf (res_code)
            );
        }

        var end_time = start_time.add_years (10);
        res_code = cert.set_expiration_time ((time_t) end_time.to_unix ());
        if (res_code != GnuTLS.ErrorCode.SUCCESS) {
            throw new CertError.CLIENT_CERT_GENERATION_ERROR (
                "Error setting activation time on client cert, GnuTLS returned status code %d.".printf (res_code)
            );
        }

        res_code = cert.set_version (1);
        if (res_code != GnuTLS.ErrorCode.SUCCESS) {
            throw new CertError.CLIENT_CERT_GENERATION_ERROR (
                "Error setting version on client cert, GnuTLS returned status code %d.".printf (res_code)
            );
        }

        uint32 serial = Posix.htonl (10);
        res_code = cert.set_serial (&serial, sizeof (uint32));
        if (res_code != GnuTLS.ErrorCode.SUCCESS) {
            throw new CertError.CLIENT_CERT_GENERATION_ERROR (
                "Error setting serial on client cert, GnuTLS returned status code %d.".printf (res_code)
            );
        }

        res_code = cert.set_dn_by_oid ("2.5.4.3", 0, common_name, common_name.length);
        if (res_code != GnuTLS.ErrorCode.SUCCESS) {
            throw new CertError.CLIENT_CERT_GENERATION_ERROR (
                "Error setting common name on client cert, GnuTLS returned status code %d.".printf (res_code)
            );
        }

        res_code = cert.sign (cert, private_key);
        if (res_code != GnuTLS.ErrorCode.SUCCESS) {
            throw new CertError.CLIENT_CERT_GENERATION_ERROR (
                "Error signing client cert, GnuTLS returned status code %d.".printf (res_code)
            );
        }

        return cert;
    }

    private uint8[] export_certificate (
        GnuTLS.X509.Certificate certificate
    ) throws CertError {
        uint8[] buff = new uint8[10000];
        size_t buff_len = buff.length;
        var res_code = certificate.export (
            GnuTLS.X509.CertificateFormat.PEM,
            buff,
            ref buff_len
        );

        if (res_code != GnuTLS.ErrorCode.SUCCESS) {
            throw new CertError.CLIENT_CERT_GENERATION_ERROR (
                "Error exporting certificate, GnuTLS returned status code %d.".printf (res_code)
            );
        }

        return buff[0:buff_len];
    }

    private async void write_to_file (
        uint8[] content,
        File file,
        Cancellable? cancel
    ) throws CertError {
        try {
            FileOutputStream pem_stream;
            if (file.query_exists ()) {
                pem_stream = yield file.replace_async (
                    null,
                    false,
                    FileCreateFlags.NONE,
                    Priority.DEFAULT,
                    cancel
               );
            } else {
                pem_stream = yield file.create_async (
                    FileCreateFlags.NONE,
                    Priority.DEFAULT,
                    cancel
               );
            }

            size_t written_len;
            var ok = yield pem_stream.write_all_async (
                content,
                Priority.DEFAULT,
                cancel,
                out written_len
            );

            if (!ok) {
                throw new CertError.CLIENT_CERT_GENERATION_ERROR (
                    "Error writing private key into file %s.".printf (file.get_path ())
                );
            }
        } catch (Error error) {
            throw new CertError.CLIENT_CERT_GENERATION_ERROR (
                "Error writing private key into file %s, cause: %s.".printf (file.get_path (), error.message)
            );
        }
    }
}

