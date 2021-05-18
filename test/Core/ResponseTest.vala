public class Starfish.Core.ResponseTest : Starfish.TestBase, Object {

    public string get_base_path () {
        return "/Starfish/Gemini/Response/";
    }

    public Gee.Map<string, TestFunc> get_tests () {
        var tests = new Gee.HashMap<string, TestFunc> ();
        tests["should-parse-invalid-status"] = should_parse_invalid_status;
        // tests["should-parse-invalid-status-with-too-small-code"] = should_parse_invalid_status_with_too_small_code;
        tests["should-parse-invalid-status-with-too-big-code"] = should_parse_invalid_status_with_too_big_code;
        tests["should-parse-input"] = should_parse_input;
        tests["should-parse-input-with-prompt"] = should_parse_input_with_prompt;
        tests["should-parse-success"] = should_parse_success;
        tests["should-parse-temporary-redirect"] = should_parse_temporary_redirect;
        tests["should-parse-permanent-redirect"] = should_parse_permanent_redirect;
        tests["should-parse-temporary-failure"] = should_parse_temporary_failure;
        tests["should-parse-temporary-failure-with-explanation"] = should_parse_temporary_failure_with_explanation;
        tests["should-parse-server-unavailable"] = should_parse_server_unavailable;
        tests["should-parse-server-unavailable-with-explanation"] = should_parse_server_unavailable_with_explanation;
        tests["should-parse-cgi-error"] = should_parse_sgi_error;
        tests["should-parse-cgi-error-with-explanation"] = should_parse_sgi_error_with_explanation;
        tests["should-parse-proxy-error"] = should_parse_proxy_error;
        tests["should-parse-proxy-error-with-explanation"] = should_parse_proxy_error_with_explanation;
        tests["should-parse-slow-down"] = should_parse_slow_down;
        tests["should-parse-permanent-failure"] = should_parse_permanent_failure;
        tests["should-parse-permanent-failure-with-explanation"] = should_parse_permanent_failure_with_explanation;
        tests["should-parse-not-found"] = should_parse_not_found;
        tests["should-parse-not-found-with-explanation"] = should_parse_not_found_with_explanation;
        tests["should-parse-gone"] = should_parse_gone;
        tests["should-parse-gone-with-explanation"] = should_parse_gone_with_explanation;
        tests["should-parse-proxy-request-refused"] = should_parse_proxy_request_refused;
        tests["should-parse-proxy-request-refused-with-explanation"] = should_parse_proxy_request_refused_with_explanation;
        tests["should-parse-bad-request"] = should_parse_bad_request;
        tests["should-parse-bad-request-with-explanation"] = should_parse_bad_request_with_explanation;
        tests["should-parse-client-certificate-required"] = should_parse_client_certificate_required;
        tests["should-parse-client-certificate-required-with-explanation"] = should_parse_client_certificate_required_with_explanation;
        tests["should-parse-certificate-not-authorised"] = should_parse_certificate_not_authorised;
        tests["should-parse-certificate-not-authorised-with-explanation"] = should_parse_certificate_not_authorised_with_explanation;
        tests["should-parse-certificate-not-valid"] = should_parse_certificate_not_valid;
        tests["should-parse-certificate-not-valid-with-explanation"] = should_parse_certificate_not_valid_with_explanation;
        return tests;
    }

    private static void should_parse_invalid_status () {
        var given_status_line = "I'm-a-teapot.";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, -1, "Unsupported server response.", true);
    }

    private static void should_parse_invalid_status_with_too_big_code () {
        var given_status_line = "418 I'm-a-teapot.";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, -1, "Unsupported server response.", true);
    }

    private static void should_parse_input () {
        var given_status_line = "10";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 10, null, false, true);
    }

    private static void should_parse_input_with_prompt () {
        var given_status_line = "10 Give something to work with!";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 10, "Give something to work with!", false, true);
    }

    private static void should_parse_success () {
        var given_status_line = "20 text/gemini";
        var given_conn = mock_connection ("# Hello world!");
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 20, "text/gemini", false, false, true);
        var actual_in = actual.connection.input_stream;
        try {
            var actual_text = (new DataInputStream (actual_in)).read_line_utf8 ();
            assert_str_eq (actual_text, "# Hello world!", "text");
        } catch (IOError e) {
            assert_not_reached ();
        }
    }

    private static void should_parse_temporary_redirect () {
        var given_status_line = "30 gemini://josipantolis.from.hr/";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 30, "gemini://josipantolis.from.hr/", false, false, false, true);
    }

    private static void should_parse_permanent_redirect () {
        var given_status_line = "31 gemini://josipantolis.from.hr/";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 31, "gemini://josipantolis.from.hr/", false, false, false, true);
    }

    private static void should_parse_temporary_failure () {
        var given_status_line = "40";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 40, null, false, false, false, false, true, false, true);
    }

    private static void should_parse_temporary_failure_with_explanation () {
        var given_status_line = "40 I don't work on Mondays.";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 40, "I don't work on Mondays.", false, false, false, false, true, false, true);
    }

    private static void should_parse_server_unavailable () {
        var given_status_line = "41";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 41, null, false, false, false, false, true, false, true);
    }

    private static void should_parse_server_unavailable_with_explanation () {
        var given_status_line = "41 Scheduled maintenance.";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 41, "Scheduled maintenance.", false, false, false, false, true, false, true);
    }

    private static void should_parse_sgi_error () {
        var given_status_line = "42";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 42, null, false, false, false, false, true, false, true);
    }

    private static void should_parse_sgi_error_with_explanation () {
        var given_status_line = "42 Failed to generate content.";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 42, "Failed to generate content.", false, false, false, false, true, false, true);
    }

    private static void should_parse_proxy_error () {
        var given_status_line = "43";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 43, null, false, false, false, false, true, false, true);
    }

    private static void should_parse_proxy_error_with_explanation () {
        var given_status_line = "43 Remote host invoked the 5th.";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 43, "Remote host invoked the 5th.", false, false, false, false, true, false, true);
    }

    private static void should_parse_slow_down () {
        var given_status_line = "44 300";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 44, "300", false, false, false, false, true, false, true);
    }

    private static void should_parse_permanent_failure () {
        var given_status_line = "50";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 50, null, false, false, false, false, false, true, true);
    }

    private static void should_parse_permanent_failure_with_explanation () {
        var given_status_line = "50 It's hopeless.";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 50, "It's hopeless.", false, false, false, false, false, true, true);
    }

    private static void should_parse_not_found () {
        var given_status_line = "51";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 51, null, false, false, false, false, false, true, true);
    }

    private static void should_parse_not_found_with_explanation () {
        var given_status_line = "51 I've never heard of this page!";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 51, "I've never heard of this page!", false, false, false, false, false, true, true);
    }

    private static void should_parse_gone () {
        var given_status_line = "52";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 52, null, false, false, false, false, false, true, true);
    }

    private static void should_parse_gone_with_explanation () {
        var given_status_line = "52 ... with the wind.";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 52, "... with the wind.", false, false, false, false, false, true, true);
    }

    private static void should_parse_proxy_request_refused () {
        var given_status_line = "53";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 53, null, false, false, false, false, false, true, true);
    }

    private static void should_parse_proxy_request_refused_with_explanation () {
        var given_status_line = "53 Just no.";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 53, "Just no.", false, false, false, false, false, true, true);
    }

    private static void should_parse_bad_request () {
        var given_status_line = "59";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 59, null, false, false, false, false, false, true, true);
    }

    private static void should_parse_bad_request_with_explanation () {
        var given_status_line = "59 Nope! Guess again!";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 59, "Nope! Guess again!", false, false, false, false, false, true, true);
    }

    private static void should_parse_client_certificate_required () {
        var given_status_line = "60";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 60, null, false, false, false, false, false, false, false, true);
    }

    private static void should_parse_client_certificate_required_with_explanation () {
        var given_status_line = "60 You should get certified!";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 60, "You should get certified!", false, false, false, false, false, false, false, true);
    }

    private static void should_parse_certificate_not_authorised () {
        var given_status_line = "61";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 61, null, false, false, false, false, false, false, false, true);
    }

    private static void should_parse_certificate_not_authorised_with_explanation () {
        var given_status_line = "61 This page is not for you.";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 61, "This page is not for you.", false, false, false, false, false, false, false, true);
    }

    private static void should_parse_certificate_not_valid () {
        var given_status_line = "62";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 62, null, false, false, false, false, false, false, false, true);
    }

    private static void should_parse_certificate_not_valid_with_explanation () {
        var given_status_line = "62 Your certificate has expired.";
        var given_conn = mock_connection ();
        var actual = new Response (new Uri (), given_status_line, given_conn);
        assert_response (actual, 62, "Your certificate has expired.", false, false, false, false, false, false, false, true);
    }

    private static IOStream mock_connection (string text = "") {
        var input = new MemoryInputStream.from_data (text.data);
        var output = new MemoryOutputStream.resizable ();
        return new SimpleIOStream (input, output);
    }

    private static void assert_response (
        Starfish.Core.Response actual,
        int expected_status,
        string? expected_meta,
        bool expected_is_unsupported_server_response = false,
        bool expected_is_input = false,
        bool expected_is_success = false,
        bool expected_is_redirect = false,
        bool expected_is_temp_fail = false,
        bool expected_is_perm_fail = false,
        bool expected_is_fail = false,
        bool expected_is_client_cert = false
    ) {
        assert_int_eq (actual.status, expected_status, "status");
        assert_str_eq (actual.meta, expected_meta, "meta");
        assert_bool_eq (actual.is_unsupported_server_response, expected_is_unsupported_server_response, "is_unsupported_server_response");
        assert_bool_eq (actual.is_input, expected_is_input, "is_input");
        assert_bool_eq (actual.is_success, expected_is_success, "is_success");
        assert_bool_eq (actual.is_redirect, expected_is_redirect, "is_redirect");
        assert_bool_eq (actual.is_temp_fail, expected_is_temp_fail, "is_temp_fail");
        assert_bool_eq (actual.is_perm_fail, expected_is_perm_fail, "is_perm_fail");
        assert_bool_eq (actual.is_fail, expected_is_fail, "is_fail");
        assert_bool_eq (actual.is_client_cert, expected_is_client_cert, "is_client_cert");
    }
}

