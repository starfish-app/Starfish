public class Starfish.Core.InternalErrorResponse : Response {

    public const int GENERAL_ERROR = -1; // meta is technical error message
    public const int CONNECTION_FAILED = -41; // meta is technical error message
    public const int STATUS_LINE_INVALID = -42; // meta is technical error message
    public const int SERVER_CERTIFICATE_INVALID = -43; // meta is technical error message
    public const int SERVER_CERTIFICATE_EXPIRED = -44; // unix timestamp of expiration
    public const int SERVER_CERTIFICATE_MISMATCH = -45;
    public const int REDIRECT_TO_NON_GEMINI_LINK = -31; // meta is the redirect link
    public const int REDIRECT_LIMIT_REACHED = -32; // meta is the redirect link
    public const int SCHEMA_NOT_SUPPORTED = -51;
    public const int FILE_ACCESS_DENIED = -61;

    public InternalErrorResponse.general_error (Uri uri, string technical_error_message) {
        this (uri, GENERAL_ERROR, technical_error_message);
    }

    public InternalErrorResponse.connection_failed (Uri uri, string technical_error_message) {
        this (uri, CONNECTION_FAILED, technical_error_message);
    }

    public InternalErrorResponse.status_line_invalid (Uri uri, string technical_error_message) {
        this (uri, STATUS_LINE_INVALID, technical_error_message);
    }

    public InternalErrorResponse.server_certificate_invalid (Uri uri, string technical_error_message) {
        this (uri, SERVER_CERTIFICATE_INVALID, technical_error_message);
    }

    public InternalErrorResponse.server_certificate_expired (Uri uri, string expired_at_str) {
        this (uri, SERVER_CERTIFICATE_EXPIRED, expired_at_str);
    }

    public InternalErrorResponse.server_certificate_mismatch (Uri uri) {
        this (uri, SERVER_CERTIFICATE_MISMATCH);
    }

    public InternalErrorResponse.redirect_to_non_gemini_link (Uri current_uri, Uri redirect_uri) {
        this (current_uri, REDIRECT_TO_NON_GEMINI_LINK, redirect_uri.to_string ());
    }

    public InternalErrorResponse.redirect_limit_reached (Uri current_uri, Uri redirect_uri) {
        this (current_uri, REDIRECT_LIMIT_REACHED, redirect_uri.to_string ());
    }

    public InternalErrorResponse.schema_not_supported (Uri uri) {
        this (uri, SCHEMA_NOT_SUPPORTED);
    }

    public InternalErrorResponse.file_access_denied (Uri uri) {
        this (uri, FILE_ACCESS_DENIED);
    }

    private InternalErrorResponse (Uri uri, int status_code, string? meta = null) {
        base (uri, Response.status_line (status_code, meta), Response.in_mem_conn ());
    }
}

