public class Starfish.Core.UriTest : Starfish.TestBase, Object {

    public string get_base_path () {
        return "/Starfish/Gemini/Uri/";
    }

    public Gee.Map<string, TestFunc> get_tests () {
        var tests = new Gee.HashMap<string, TestFunc> ();
        tests["should-parse-various-schemes"] = should_parse_various_schemes;
        tests["should-remove-dot-segments"] = should_remove_dot_segments;
        tests["should-parse-relative-urls"] = should_parse_relative_urls;
        tests["should-url-encode"] = should_url_encode;
        tests["should-go-up-in-path"] = should_go_up_in_path;
        tests["should-go-to-root"] = should_go_to_root;
        return tests;
    }

    public static void should_parse_various_schemes () {
        try {
            assert_parsed_uri (
                "gemini://chris.vittal.dev/rfcs/txt/rfc3986.txt",
                new Uri ("gemini", null, "chris.vittal.dev", -1, "/rfcs/txt/rfc3986.txt"),
                "ftp://ftp.is.co.za/rfc/rfc1808.txt",
                new Uri ("ftp", null, "ftp.is.co.za", -1, "/rfc/rfc1808.txt"),
                "http://www.ietf.org/rfc/rfc2396.txt",
                new Uri ("http", null, "www.ietf.org", -1, "/rfc/rfc2396.txt"),
                "ldap://[2001:db8::7]/c=GB?objectClass?one",
                new Uri ("ldap", null, "[2001:db8::7]", -1, "/c=GB", "objectClass?one"),
                "mailto:John.Doe@example.com",
                new Uri ("mailto", null, "", -1, "John.Doe@example.com"),
                "news:comp.infosystems.www.servers.unix",
                new Uri ("news", null, "", -1, "comp.infosystems.www.servers.unix"),
                "tel:+1-816-555-1212",
                new Uri ("tel", null, "", -1, "+1-816-555-1212"),
                "telnet://192.0.2.16:80/",
                new Uri ("telnet", null, "192.0.2.16", 80, "/"),
                "urn:oasis:names:specification:docbook:dtd:xml:4.1.2",
                new Uri ("urn", null, "", -1, "oasis:names:specification:docbook:dtd:xml:4.1.2")
            );
        } catch (UriError e) {
            assert_not_reached ();
        }
    }

    public static void should_remove_dot_segments () {
        try {
            assert_parsed_uri (
                "/a/b/c/./../../g",
                new Uri ("gemini", null, "", -1, "/a/g"),
                "mid/content=5/../6",
                new Uri ("gemini", null, "", -1, "mid/6")
            );
        } catch (UriError e) {
            assert_not_reached ();
        }
    }

    public static void should_parse_relative_urls () {
        try {
            var base_url = Uri.parse ("http://a/b/c/d;p?q");
            assert_parsed_relative_uri (
              "g:h", base_url, Uri.parse ("g:h"),
              "g", base_url, Uri.parse ("http://a/b/c/g"),
              "./g", base_url, Uri.parse("http://a/b/c/g"),
              "g/", base_url, Uri.parse("http://a/b/c/g/"),
              "/g", base_url, Uri.parse("http://a/g"),
              "//g", base_url, Uri.parse("http://g"),
              "?y", base_url, Uri.parse("http://a/b/c/d;p?y"),
              "g?y", base_url, Uri.parse("http://a/b/c/g?y"),
              "#s", base_url, Uri.parse("http://a/b/c/d;p?q#s"),
              "g#s", base_url, Uri.parse("http://a/b/c/g#s"),
              "g?y#s", base_url, Uri.parse("http://a/b/c/g?y#s"),
              ";x", base_url, Uri.parse("http://a/b/c/;x"),
              "g;x", base_url, Uri.parse("http://a/b/c/g;x"),
              "g;x?y#s", base_url, Uri.parse("http://a/b/c/g;x?y#s")
            );
            assert_parsed_relative_uri (
              "", base_url, Uri.parse("http://a/b/c/d;p?q"),
              ".", base_url, Uri.parse("http://a/b/c/"),
              "./", base_url, Uri.parse("http://a/b/c/"),
              "..", base_url, Uri.parse("http://a/b/"),
              "../", base_url, Uri.parse("http://a/b/"),
              "../g", base_url, Uri.parse("http://a/b/g"),
              "../..", base_url, Uri.parse("http://a/"),
              "../../", base_url, Uri.parse("http://a/"),
              "../../g", base_url, Uri.parse("http://a/g"),
              "../../../g", base_url, Uri.parse("http://a/g"),
              "../../../../g", base_url, Uri.parse("http://a/g"),
              "/./g", base_url, Uri.parse("http://a/g"),
              "/../g", base_url, Uri.parse("http://a/g"),
              "g.", base_url, Uri.parse("http://a/b/c/g."),
              ".g", base_url, Uri.parse("http://a/b/c/.g"),
              "g..", base_url, Uri.parse("http://a/b/c/g.."),
              "..g", base_url, Uri.parse("http://a/b/c/..g"),
              "./../g", base_url, Uri.parse("http://a/b/g"),
              "./g/.", base_url, Uri.parse("http://a/b/c/g/"),
              "g/./h", base_url, Uri.parse("http://a/b/c/g/h"),
              "g/../h", base_url, Uri.parse("http://a/b/c/h")
            );
            assert_parsed_relative_uri (
              "g;x=1/./y", base_url, Uri.parse("http://a/b/c/g;x=1/y"),
              "g;x=1/../y", base_url, Uri.parse("http://a/b/c/y"),
              "g?y/./x", base_url, Uri.parse("http://a/b/c/g?y/./x"),
              "g?y/../x", base_url, Uri.parse("http://a/b/c/g?y/../x"),
              "g#s/./x", base_url, Uri.parse("http://a/b/c/g#s/./x"),
              "g#s/../x", base_url, Uri.parse("http://a/b/c/g#s/../x"),
              "http:g", base_url, Uri.parse("http:g")
            );
        } catch (UriError e) {
            assert_not_reached ();
        }
    }

    public static void should_url_encode () {
        assert_str_eq (Uri.encode (null), null);
        assert_str_eq (Uri.encode (""), "");
        assert_str_eq (Uri.encode ("% "), "%25%20");
        assert_str_eq (Uri.encode ("abcdefghijklmnopqrstuvwxyz"), "abcdefghijklmnopqrstuvwxyz");
        assert_str_eq (Uri.encode ("ABCDEFGHIJKLMNOPQRSTUVWXYZ"), "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        assert_str_eq (Uri.encode ("0123456789"), "0123456789");
        assert_str_eq (Uri.encode ("Starfish: ⭐️!"), "Starfish%3a%20%e2%ad%90%ef%b8%8f%21");
        assert_str_eq (Uri.encode (" \t\n\r"), "%20%09%0a%0d");
        assert_str_eq (Uri.encode ("Здравствуйте, Россия!"), "%d0%97%d0%b4%d1%80%d0%b0%d0%b2%d1%81%d1%82%d0%b2%d1%83%d0%b9%d1%82%d0%b5%2c%20%d0%a0%d0%be%d1%81%d1%81%d0%b8%d1%8f%21");
        assert_str_eq (Uri.encode ("안녕하세요 코리아!"), "%ec%95%88%eb%85%95%ed%95%98%ec%84%b8%ec%9a%94%20%ec%bd%94%eb%a6%ac%ec%95%84%21");
        assert_str_eq (Uri.encode ("こんにちは日本!"), "%e3%81%93%e3%82%93%e3%81%ab%e3%81%a1%e3%81%af%e6%97%a5%e6%9c%ac%21");
        assert_str_eq (Uri.encode ("नमस्ते भारत!"), "%e0%a4%a8%e0%a4%ae%e0%a4%b8%e0%a5%8d%e0%a4%a4%e0%a5%87%20%e0%a4%ad%e0%a4%be%e0%a4%b0%e0%a4%a4%21");
        assert_str_eq (Uri.encode ("čćđšž"), "%c4%8d%c4%87%c4%91%c5%a1%c5%be");
    }

    public static void should_go_up_in_path () {
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965).one_up (),
            new Uri ("gemini", null, "domain", 1965)
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "/").one_up (),
            new Uri ("gemini", null, "domain", 1965)
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "//").one_up (),
            new Uri ("gemini", null, "domain", 1965, "/")
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "/foo").one_up (),
            new Uri ("gemini", null, "domain", 1965, "/")
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "/foo/").one_up (),
            new Uri ("gemini", null, "domain", 1965, "/foo")
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "/foo/bar").one_up (),
            new Uri ("gemini", null, "domain", 1965, "/foo/")
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "/foo//bar").one_up (),
            new Uri ("gemini", null, "domain", 1965, "/foo//")
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "/foo", "query").one_up (),
            new Uri ("gemini", null, "domain", 1965, "/")
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "/foo", null, "fragment").one_up (),
            new Uri ("gemini", null, "domain", 1965, "/")
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "/foo", "query", "fragment").one_up (),
            new Uri ("gemini", null, "domain", 1965, "/")
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "", "query", "fragment").one_up (),
            new Uri ("gemini", null, "domain", 1965)
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "/", "query", "fragment").one_up (),
            new Uri ("gemini", null, "domain", 1965)
        );
    }

    public static void should_go_to_root () {
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965).root (),
            new Uri ("gemini", null, "domain", 1965)
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "/").root (),
            new Uri ("gemini", null, "domain", 1965)
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "/foo").root (),
            new Uri ("gemini", null, "domain", 1965)
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "/~barman").root (),
            new Uri ("gemini", null, "domain", 1965, "/~barman")
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "/foo/~barman").root (),
            new Uri ("gemini", null, "domain", 1965, "/foo/~barman")
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "/not~a~user").root (),
            new Uri ("gemini", null, "domain", 1965)
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "/foo/~barman/").root (),
            new Uri ("gemini", null, "domain", 1965, "/foo/~barman")
        );
        assert_uri_eq (
            new Uri ("gemini", null, "domain", 1965, "/foo/~barman/bazz").root (),
            new Uri ("gemini", null, "domain", 1965, "/foo/~barman")
        );
    }

    private static void assert_parsed_uri (string given_raw, Uri expected_uri, ...) throws UriError {
        var actual_uri = Uri.parse (given_raw);
        assert_uri_eq (actual_uri, expected_uri);
        var rest = va_list ();
        while (true) {
            string? given = rest.arg ();
            if (given == null) {
                break;
            }
            Uri actual = Uri.parse (given);
            Uri expected = rest.arg ();
            assert_uri_eq (actual, expected);
        }
    }

    private static void assert_parsed_relative_uri (string given_raw, Uri base_uri, Uri expected_uri, ...) throws UriError {
        var actual_uri = Uri.parse (given_raw, base_uri);
        assert_uri_eq (actual_uri, expected_uri);
        var rest = va_list ();
        while (true) {
            string? given = rest.arg ();
            if (given == null) {
                break;
            }
            Uri b_uri = rest.arg ();
            Uri actual = Uri.parse (given, b_uri);
            Uri expected = rest.arg ();
            assert_uri_eq (actual, expected);
        }
    }

    private static void assert_uri_eq (Uri actual, Uri expected) {
        assert_str_eq (actual.scheme, expected.scheme, "scheme");
        assert_str_eq (actual.userinfo, expected.userinfo, "userinfo");
        assert_str_eq (actual.host, expected.host, "host");
        assert_int_eq (actual.port, expected.port, "port");
        assert_str_eq (actual.path, expected.path, "path");
        assert_str_eq (actual.query, expected.query, "query");
        assert_str_eq (actual.fragment, expected.fragment, "fragment");
    }
}

