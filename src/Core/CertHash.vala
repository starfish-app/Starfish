public class Starfish.Core.CertHash : Object {

    public string host_hash { get; construct; }
    public DateTime expires_at { get; construct; }
    public string fingerprint { get; construct; }

    private CertHash (
        string host_hash,
        DateTime expires_at,
        string fingerprint
    ) {
        Object (
            host_hash: host_hash,
            expires_at: expires_at,
            fingerprint: fingerprint
        );
    }

    // Can throw FINGERPRINTING_ERROR
    public static CertHash from_cert (CertInfo cert) throws CertError{
        return new CertHash (
            Checksum.compute_for_string (ChecksumType.SHA1, cert.host),
            cert.expires_at,
            cert.fingerprint
        );
    }

    public static CertHash? from_file_row (string? row) {
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

        var host_hash = sections[0];
        var expires_at = new DateTime.from_unix_utc (expires_at_unix);
        var fingerprint = sections[2];
        return new CertHash (host_hash, expires_at, fingerprint);
    }

    public string to_file_row () {
        return "%s %lld %s\n".printf (
            this.host_hash,
            this.expires_at.to_unix (),
            this.fingerprint
        );
    }
}

