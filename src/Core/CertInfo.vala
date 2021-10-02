public class Starfish.Core.CertInfo : Object {

    public string? domain { get; construct; }
    public string domain_hash { get; construct; }
    public DateTime expires_at { get; construct; }
    public string fingerprint { get; construct; }

    public CertInfo (DateTime expires_at, string fingerprint, string domain_hash, string? domain = null) {
        Object (
            domain: domain,
            domain_hash: domain_hash,
            expires_at: expires_at,
            fingerprint: fingerprint
        );
    }

    public static CertInfo parse (SocketConnectable identity, TlsCertificate cert) throws CertError {
        var tls_cert = to_tls_cert (cert);
        var domain = identity.to_string ();
        var domain_hash = Checksum.compute_for_string (ChecksumType.SHA1, domain);
        return new CertInfo (
            expiration_date (tls_cert),
            compute_fingerprint (tls_cert),
            domain_hash,
            domain
        );
    }

    private static GnuTLS.X509.Certificate to_tls_cert (TlsCertificate cert) throws CertError {
        var pem = cert.certificate_pem;
        var data = GnuTLS.Datum() {
            data = pem,
            size = pem.length
        };

        var tls_cert = GnuTLS.X509.Certificate.create();
        var res_code = tls_cert.import (ref data, GnuTLS.X509.CertificateFormat.PEM);
        if (res_code != 0) {
            throw new CertError.PARSING_ERROR ("Error parsing TLS certificate, GnuTLS returned status code %d".printf (res_code));
        }

        return tls_cert;
    }

    private static DateTime expiration_date (GnuTLS.X509.Certificate cert) {
        var exp_date = Date();
        exp_date.set_time_t (cert.get_expiration_time ());
        Time exp_time;
        exp_date.to_time (out exp_time);
        return new DateTime.utc (
            exp_time.year + 1900,
            exp_time.month + 1,
            exp_time.day,
            exp_time.hour,
            exp_time.minute,
            exp_time.second
        );
    }

    private static string compute_fingerprint (GnuTLS.X509.Certificate cert) throws CertError {
        uint8[] buff = new uint8[20];
        size_t buf_size = 20;
        var res_code = cert.get_fingerprint (GnuTLS.DigestAlgorithm.SHA1, buff, ref buf_size);
        if (res_code != 0) {
            throw new CertError.FINGERPRINTING_ERROR ("Error fingerprinting TLS certificate, GnuTLS returned status code %d".printf (res_code));
        }

        var sha1 = "";
        foreach (var c in buff) {
            sha1 += "%x".printf (c);
        }

        return sha1;
    }

    public string to_string () {
        return "CertInfo{ domain: %s, expires_at: %s, fingerprint: %s }".printf (
            domain,
            expires_at.format ("%X %d-%m-%Y"),
            fingerprint
        );
    }
}

