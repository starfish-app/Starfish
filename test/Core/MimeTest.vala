public class Starfish.Core.MimeTest : Starfish.TestBase, Object {

    public string get_base_path () {
        return "/Starfish/Gemini/Mime/";
    }

    public Gee.Map<string, TestFunc> get_tests () {
        var tests = new Gee.HashMap<string, TestFunc> ();
        tests["should-parse-text-plain"] = should_parse_text_plain;
        tests["should-parse-text-gemini"] = should_parse_text_gemini;
        tests["should-parse-text-gemini-with-charset"] = should_parse_text_gemini_with_charset;
        tests["should-parse-text-gemini-with-single-lang"] = should_parse_text_gemini_with_single_lang;
        tests["should-parse-text-gemini-with-two-langs"] = should_parse_text_gemini_with_two_langs;
        tests["should-parse-text-gemini-with-charset-and-lang"] = should_parse_text_gemini_with_charset_and_lang;
        tests["should-parse-text-gemini-with-lang-and-charset"] = should_parse_text_gemini_with_lang_and_charset;
        tests["should-parse-text-plain-with-charset"] = should_parse_text_plain_with_charset;
        tests["should-parse-text-gemini-with-spacing"] = should_parse_text_gemini_with_spacing;
        tests["should-parse-text-gemini-with-unknown-elements"] = should_parse_text_gemini_with_unknown_elements;
        tests["should-parse-image-jpeg"] = should_parse_image_jpeg;
        return tests;
    }

    private static void should_parse_text_plain () {
        var given_mime = "text/plain";
        var actual = new  Starfish.Core.Mime (given_mime);
        assert_mime (actual, "text", "plain", "utf-8", {}, false);
    }

    private static void should_parse_text_gemini () {
        var given_mime = "text/gemini";
        var actual = new  Starfish.Core.Mime (given_mime);
        assert_mime (actual, "text", "gemini", "utf-8", {}, true);
    }

    private static void should_parse_text_gemini_with_charset () {
        var given_mime = "text/gemini;charset=us-ascii";
        var actual = new  Starfish.Core.Mime (given_mime);
        assert_mime (actual, "text", "gemini", "us-ascii", {}, true);
    }

    private static void should_parse_text_gemini_with_single_lang () {
        var given_mime = "text/gemini;lang=zh-Hans-CN";
        var actual = new  Starfish.Core.Mime (given_mime);
        assert_mime (actual, "text", "gemini", "utf-8", {"zh-Hans-CN"}, true);
    }

    private static void should_parse_text_gemini_with_two_langs () {
        var given_mime = "text/gemini;lang=en,fr";
        var actual = new  Starfish.Core.Mime (given_mime);
        assert_mime (actual, "text", "gemini", "utf-8", {"en", "fr"}, true);
    }

    private static void should_parse_text_gemini_with_charset_and_lang () {
        var given_mime = "text/gemini;charset=us-ascii;lang=en";
        var actual = new  Starfish.Core.Mime (given_mime);
        assert_mime (actual, "text", "gemini", "us-ascii", {"en"}, true);
    }

    private static void should_parse_text_gemini_with_lang_and_charset () {
        var given_mime = "text/gemini;lang=en;charset=us-ascii";
        var actual = new  Starfish.Core.Mime (given_mime);
        assert_mime (actual, "text", "gemini", "us-ascii", {"en"}, true);
    }

    private static void should_parse_text_plain_with_charset () {
        var given_mime = "text/plain;charset=us-ascii";
        var actual = new  Starfish.Core.Mime (given_mime);
        assert_mime (actual, "text", "plain", "us-ascii", {}, false);
    }

    private static void should_parse_text_gemini_with_spacing () {
        var given_mime = "text/gemini ;lang = en, fr ;;charset = us-ascii;;;";
        var actual = new  Starfish.Core.Mime (given_mime);
        assert_mime (actual, "text", "gemini", "us-ascii", {"en", "fr"}, true);
    }

    private static void should_parse_text_gemini_with_unknown_elements () {
        var given_mime = "text/plain;madeUp=totally;invalid-format;;";
        var actual = new  Starfish.Core.Mime (given_mime);
        assert_mime (actual, "text", "plain", "utf-8", {}, false);
    }

    private static void should_parse_image_jpeg () {
        var given_mime = "image/jpeg";
        var actual = new  Starfish.Core.Mime (given_mime);
        assert_mime (actual, "image", "jpeg", "utf-8", {}, false);
    }

    private static void assert_mime (
        Mime actual,
        string expected_main_type,
        string expected_sub_type,
        string expected_charset,
        string[] expected_langs,
        bool expected_is_gemtext
    ) {
        assert (actual != null);
        assert_str_eq (actual.main_type, expected_main_type, "main_type");
        assert_str_eq (actual.sub_type, expected_sub_type, "sub_type");
        assert_str_eq (actual.charset, expected_charset, "charset");
        assert_str_arrays (actual.langs, expected_langs, "langs");
        assert_bool_eq (actual.is_gemtext, expected_is_gemtext, "is_gemtext");
    }
}

