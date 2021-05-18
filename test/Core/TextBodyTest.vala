public class Starfish.Core.TextBodyTest : Starfish.TestBase, BodyTestBase, Object {

    public string get_base_path () {
        return "/Starfish/Gemini/TextBody/";
    }

    public Gee.Map<string, TestFunc> get_tests () {
        var tests = new Gee.HashMap<string, TestFunc> ();
        tests["should-read-lines-from-string"] = should_read_lines_from_string;
        tests["should-read-lines-from-stream"] = should_read_lines_from_stream;
        tests["should-convert-to-utf-8"] = should_convert_to_utf_8;
        return tests;
    }

    private static string TEXT = """Line 1.
Line 2.

Line 4.

""";

    public static void should_read_lines_from_string () {
        var body = new TextBody.from_string (TEXT);
        var actual_lines = collect_lines_from (body);
        assert_line_arrays (
            actual_lines,
            {
                expected_text_line ("Line 1."),
                expected_text_line ("Line 2."),
                expected_text_line (""),
                expected_text_line ("Line 4."),
                expected_text_line ("")
            }
        );
    }

    public static void should_read_lines_from_stream () {
        var given_in_stream = new MemoryInputStream.from_data (TEXT.data);
        var mock_out_stream = new MemoryOutputStream.resizable ();
        var given_io_stream = new SimpleIOStream (given_in_stream, mock_out_stream);
        var body = new TextBody (new Mime ("text/plain"), given_io_stream);
        var actual_lines = collect_lines_from (body);
        assert_line_arrays (
            actual_lines,
            {
                expected_text_line ("Line 1."),
                expected_text_line ("Line 2."),
                expected_text_line (""),
                expected_text_line ("Line 4."),
                expected_text_line ("")
            }
        );
    }

    public static void should_convert_to_utf_8 () {
        var given_string = "Ïñtèrñàtìòñálízâtîøñ";
        var in_mem_stream = new MemoryInputStream.from_data (given_string.data);
        CharsetConverter converter;
        try {
            converter = new CharsetConverter ("ISO-8859-1", "UTF-8");
        } catch (Error e) {
            assert_not_reached ();
        }
        var given_in_stream = new ConverterInputStream (in_mem_stream, converter);
        var mock_out_stream = new MemoryOutputStream.resizable ();
        var given_io_stream = new SimpleIOStream (given_in_stream, mock_out_stream);
        var given_mime = new Mime ("text/plain; charset=ISO-8859-1");
        var body = new TextBody (given_mime, given_io_stream);
        var actual_lines = collect_lines_from (body);
        assert_line_arrays (
            actual_lines,
            { expected_text_line (given_string) }
        );
    }
}

