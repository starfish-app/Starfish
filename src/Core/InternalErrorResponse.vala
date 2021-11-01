public class Starfish.Core.InternalErrorResponse : Response {

    public const int GENERAL_ERROR = -1; // meta is technical error message
    public const int CONNECTION_FAILED = -41; // meta is technical error message
    public const int STATUS_LINE_INVALID = -42; // meta is technical error message
    public const int SERVER_CERTIFICATE_INVALID = -43; // meta is technical error message
    public const int SERVER_CERTIFICATE_MISMATCH = -45;
    public const int SERVER_CERTIFICATE_NOT_APPLICABLE = -46; // meta is requested host
    public const int REDIRECT_TO_NON_GEMINI_LINK = -31; // meta is the redirect link
    public const int REDIRECT_LIMIT_REACHED = -32; // meta is the redirect link
    public const int SCHEMA_NOT_SUPPORTED = -51;
    public const int FILE_ACCESS_DENIED = -61;

    public InternalErrorResponse.general_error (CertInfo? cert_info, Uri uri, string technical_error_message) {
        this (cert_info, uri, GENERAL_ERROR, technical_error_message);
    }

    public InternalErrorResponse.connection_failed (CertInfo? cert_info, Uri uri, string technical_error_message) {
        this (cert_info, uri, CONNECTION_FAILED, technical_error_message);
    }

    public InternalErrorResponse.status_line_invalid (CertInfo? cert_info, Uri uri, string technical_error_message) {
        this (cert_info, uri, STATUS_LINE_INVALID, technical_error_message);
    }

    public InternalErrorResponse.server_certificate_invalid (CertInfo? cert_info, Uri uri, string technical_error_message) {
        this (cert_info, uri, SERVER_CERTIFICATE_INVALID, technical_error_message);
    }

    public InternalErrorResponse.server_certificate_mismatch (CertInfo? cert_info, Uri uri) {
        this (cert_info, uri, SERVER_CERTIFICATE_MISMATCH);
    }

    public InternalErrorResponse.server_certificate_not_applicable (CertInfo? cert_info, Uri uri) {
        this (cert_info, uri, SERVER_CERTIFICATE_NOT_APPLICABLE, uri.host);
    }

    public InternalErrorResponse.redirect_to_non_gemini_link (CertInfo? cert_info, Uri current_uri, Uri redirect_uri) {
        this (cert_info, current_uri, REDIRECT_TO_NON_GEMINI_LINK, redirect_uri.to_string ());
    }

    public InternalErrorResponse.redirect_limit_reached (CertInfo? cert_info, Uri current_uri, Uri redirect_uri) {
        this (cert_info, current_uri, REDIRECT_LIMIT_REACHED, redirect_uri.to_string ());
    }

    public InternalErrorResponse.schema_not_supported (Uri uri) {
        this (null, uri, SCHEMA_NOT_SUPPORTED);
    }

    public InternalErrorResponse.file_access_denied (Uri uri) {
        this (null, uri, FILE_ACCESS_DENIED);
    }

    private InternalErrorResponse (CertInfo? cert_info, Uri uri, int status_code, string? meta = null) {
        base (uri, Response.status_line (status_code, meta), Response.in_mem_conn (), cert_info);
    }
}

