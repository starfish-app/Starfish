public class Starfish.Core.LineTest : Starfish.TestBase, Object {

    public string get_base_path () {
        return "/Starfish/Gemini/Line/";
    }

    public Gee.Map<string, TestFunc> get_tests () {
        var tests = new Gee.HashMap<string, TestFunc> ();
        tests["should-handle-text"] = should_handle_text;
        tests["should-handle-link"] = should_handle_link;
        tests["should-handle-link-with-one-space"] = should_handle_link_with_one_space;
        tests["should-handle-link-with-many-spaces"] = should_handle_link_with_many_spaces;
        tests["should-handle-link-with-desc"] = should_handle_link_with_desc;
        tests["should-handle-link-with-desc-and-spaces"] = should_handle_link_with_desc_and_spaces;
        tests["should-handle-preformatted-start"] = should_handle_preformatted_start;
        tests["should-handle-preformatted-start-with_desc"] = should_handle_preformatted_start_with_desc;
        tests["should-handle-preformatted-end"] = should_handle_preformatted_end;
        tests["should-handle-preformatted"] = should_handle_preformatted;
        tests["should-handle-heading-1"] = should_handle_heading_1;
        tests["should-handle-heading-1-with-space"] = should_handle_heading_1_with_space;
        tests["should-handle-heading-1-with-tab"] = should_handle_heading_1_with_tab;
        tests["should-handle-heading-2"] = should_handle_heading_2;
        tests["should-handle-heading-2-with-space"] = should_handle_heading_2_with_space;
        tests["should-handle-heading-2-with-tab"] = should_handle_heading_2_with_tab;
        tests["should-handle-heading-3"] = should_handle_heading_3;
        tests["should-handle-heading-3-with-space"] = should_handle_heading_3_with_space;
        tests["should-handle-heading-3-with-tab"] = should_handle_heading_3_with_tab;
        tests["should-handle-list-item"] = should_handle_list_item;
        tests["should-handle-quote"] = should_handle_quote;
        return tests;
    }

    private static void should_handle_text () {
        var given_content = "Hello world!";
        var actual = new Line (given_content, LineType.TEXT);
        assert_line (actual, given_content);
    }

    private static void should_handle_link () {
        var given_content = "=>gemni://josipantolis.from.hr/starfish";
        var actual = new Line (given_content, LineType.LINK);
        assert_line (
            actual,
            "gemni://josipantolis.from.hr/starfish",
            "gemni://josipantolis.from.hr/starfish",
            "gemni://josipantolis.from.hr/starfish"
        );
    }

     private static void should_handle_link_with_one_space () {
        var given_content = "=> gemni://josipantolis.from.hr/starfish";
        var actual = new Line (given_content, LineType.LINK);
        assert_line (
            actual,
            "gemni://josipantolis.from.hr/starfish",
            "gemni://josipantolis.from.hr/starfish",
            "gemni://josipantolis.from.hr/starfish"
        );
    }

    private static void should_handle_link_with_many_spaces () {
        var given_content = "=> \t\t  \t gemni://josipantolis.from.hr/starfish";
        var actual = new Line (given_content, LineType.LINK);
        assert_line (
            actual,
            "gemni://josipantolis.from.hr/starfish",
            "gemni://josipantolis.from.hr/starfish",
            "gemni://josipantolis.from.hr/starfish"
        );
    }

    private static void should_handle_link_with_desc () {
        var given_content = "=>gemni://josipantolis.from.hr/starfish ⭐️ Starfish project";
        var actual = new Line (given_content, LineType.LINK);
        assert_line (
            actual,
            "⭐️ Starfish project",
            "gemni://josipantolis.from.hr/starfish",
            "⭐️ Starfish project"
        );
    }

    private static void should_handle_link_with_desc_and_spaces () {
        var given_content = "=> \t\t  gemni://josipantolis.from.hr/starfish \t  \t⭐️ Starfish project \t";
        var actual = new Line (given_content, LineType.LINK);
        assert_line (
            actual,
            "⭐️ Starfish project",
            "gemni://josipantolis.from.hr/starfish",
            "⭐️ Starfish project"
        );
    }

    private static void should_handle_preformatted_start () {
        var actual = new Line ("```", LineType.PREFORMATTED_START);
        assert_line (actual, "", null, null, "");
    }

    private static void should_handle_preformatted_start_with_desc () {
        var actual = new Line ("```Descrption!", LineType.PREFORMATTED_START);
        assert_line (actual, "", null, null, "Descrption!");
    }

    private static void should_handle_preformatted_end () {
        var actual = new Line ("```must be ignored", LineType.PREFORMATTED_END);
        assert_line (actual, "");
    }

    private static void should_handle_preformatted () {
        var given_content = "\t  ✧･ﾟ: *✧･ﾟ:* *:･ﾟ✧*:･ﾟ✧  \t";
        var actual = new Line (given_content, LineType.PREFORMATTED);
        assert_line (actual, given_content);
    }

    private static void should_handle_heading_1 () {
        var actual = new Line ("#Heading 1", LineType.HEADING_1);
        assert_line (actual, "Heading 1");
    }

    private static void should_handle_heading_1_with_space () {
        var actual = new Line ("# Heading 1", LineType.HEADING_1);
        assert_line (actual, "Heading 1");
    }

    private static void should_handle_heading_1_with_tab () {
        var actual = new Line ("#\tHeading 1", LineType.HEADING_1);
        assert_line (actual, "Heading 1");
    }

    private static void should_handle_heading_2 () {
        var actual = new Line ("##Heading 2", LineType.HEADING_2);
        assert_line (actual, "Heading 2");
    }

    private static void should_handle_heading_2_with_space () {
        var actual = new Line ("## Heading 2", LineType.HEADING_2);
        assert_line (actual, "Heading 2");
    }

    private static void should_handle_heading_2_with_tab () {
        var actual = new Line ("##\tHeading 2", LineType.HEADING_2);
        assert_line (actual, "Heading 2");
    }

    private static void should_handle_heading_3 () {
        var actual = new Line ("###Heading 3", LineType.HEADING_3);
        assert_line (actual, "Heading 3");
    }

    private static void should_handle_heading_3_with_space () {
        var actual = new Line ("### Heading 3", LineType.HEADING_3);
        assert_line (actual, "Heading 3");
    }

    private static void should_handle_heading_3_with_tab () {
        var actual = new Line ("###\tHeading 3", LineType.HEADING_3);
        assert_line (actual, "Heading 3");
    }

    private static void should_handle_list_item () {
        var actual = new Line ("* List item \t", LineType.LIST_ITEM);
        assert_line (actual, "List item \t");
    }

    private static void should_handle_quote () {
        var actual = new Line (">I’m coming back in… and it’s the saddest moment of my life.", LineType.QUOTE);
        assert_line (actual, "I’m coming back in… and it’s the saddest moment of my life.");
    }

    private static void assert_line (
        Line actual,
        string expected_display_content,
        string? expedted_url = null,
        string? expected_url_desc = null,
        string? expected_alt_text = null
    ) {
        assert_str_eq (actual.get_display_content (), expected_display_content, "get_display_content");
        assert_str_eq (actual.get_url (), expedted_url, "get_url");
        assert_str_eq (actual.get_url_desc (), expected_url_desc, "get_url_desc");
        assert_str_eq (actual.get_alt_text (), expected_alt_text, "get_alt_text");
    }

}
