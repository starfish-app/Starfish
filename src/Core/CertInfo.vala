public class Starfish.Core.CertInfo : Object {

    public string host { get; construct; }
    public DateTime active_from { get; construct; }
    public DateTime expires_at { get; construct; }
    public bool hostname_check { get; construct; }
    public string fingerprint { get; construct; }
    public string full_print { get; construct; }
    public string? common_name { get; construct; }
    public string? country_name { get; construct; }
    public string? organization_name { get; construct; }

    private CertInfo (
        string host,
        DateTime active_from,
        DateTime expires_at,
        bool hostname_check,
        string fingerprint,
        string full_print,
        string? common_name = null,
        string? country_name = null,
        string? organization_name = null
    ) {
        Object (
            host: host,
            active_from: active_from,
            expires_at: expires_at,
            hostname_check: hostname_check,
            fingerprint: fingerprint,
            full_print: full_print,
            common_name: common_name,
            country_name: country_name,
            organization_name: organization_name
        );
    }

    // Can throw PARSING_ERROR
    public static CertInfo parse (Uri uri, TlsCertificate tls_cert) throws CertError {
        var cert = import_cert (tls_cert);
        return new CertInfo (
            uri.host,
            extract_active_from (cert),
            extract_expires_at (cert),
            extract_hostname_check (cert, uri),
            calculate_fingerprint (cert),
            print_cert (cert),
            read_dn (cert, "2.5.4.3"),
            read_dn (cert, "2.5.4.6"),
            read_dn (cert, "2.5.4.10")
        );
    }

    public bool is_inactive () {
        var now = new DateTime.now_utc ();
        return now.compare (this.active_from) < 0;
    }

    public bool is_expired () {
        var now = new DateTime.now_utc ();
        return now.compare (this.expires_at) >= 0;
    }

    public bool is_not_applicable_to_uri () {
        return hostname_check;
    }

    private static DateTime extract_active_from (
        GnuTLS.X509.Certificate cert
    ) {
        var utc_time = (int64) cert.get_activation_time ();
        return new DateTime.from_unix_utc (utc_time);
    }

    private static DateTime extract_expires_at (
        GnuTLS.X509.Certificate cert
    ) {
        var utc_time = (int64) cert.get_expiration_time ();
        return new DateTime.from_unix_utc (utc_time);
    }

    private static bool extract_hostname_check (
        GnuTLS.X509.Certificate cert,
        Uri requested_uri
    ) {
        return !cert.check_hostname (requested_uri.host);
    }

    // Can throw FINGERPRINTING_ERROR
    private static string calculate_fingerprint (
        GnuTLS.X509.Certificate cert
    ) throws CertError {
        uint8[] buff = new uint8[20];
        size_t buf_size = 20;
        var res_code = cert.get_fingerprint (GnuTLS.DigestAlgorithm.SHA1, buff, ref buf_size);
        if (res_code != GnuTLS.ErrorCode.SUCCESS) {
            throw new CertError.FINGERPRINTING_ERROR (
                "Error fingerprinting TLS certificate, GnuTLS returned status code %d".printf (res_code)
            );
        }

        var sha1 = "";
        foreach (var c in buff) {
            sha1 += "%x".printf (c);
        }

        return sha1;
    }

    // Can throw PRINTING_ERROR
    private static string print_cert (
        GnuTLS.X509.Certificate cert
    ) throws CertError {
        GnuTLS.Datum data;
        var res_code = cert.print (GnuTLS.CertificatePrintFormats.FULL, out data);
        if (res_code != GnuTLS.ErrorCode.SUCCESS) {
            throw new CertError.PRINTING_ERROR (
                "Error printing TLS certificate, GnuTLS returned status code %d".printf (res_code)
            );
        }

        return (string) data.data;
    }

    private static GnuTLS.X509.Certificate import_cert (TlsCertificate tls_cert) throws CertError {
        var pem = tls_cert.certificate_pem;
        var data = GnuTLS.Datum() { data = pem, size = pem.length };
        var cert = GnuTLS.X509.Certificate.create();
        var res_code = cert.import (ref data, GnuTLS.X509.CertificateFormat.PEM);
        if (res_code != GnuTLS.ErrorCode.SUCCESS) {
            throw new CertError.PARSING_ERROR (
                "Error parsing TLS certificate, GnuTLS returned status code %d".printf (res_code)
            );
        }

        return cert;
    }

    private static string? read_dn (GnuTLS.X509.Certificate cert, string key) {
        uint8[] buffer = new uint8[4096];
        size_t buffer_len = buffer.length;
        var res_code = cert.get_dn_by_oid (key, 0, 0, buffer, ref buffer_len);
        if (res_code != GnuTLS.ErrorCode.SUCCESS) {
            return null;
        }

        return (string) buffer;
    }
}

