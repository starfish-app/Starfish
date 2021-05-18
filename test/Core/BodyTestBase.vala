public interface Starfish.Core.BodyTestBase : Starfish.TestBase {

    public static Line[] collect_lines_from (TextBody body) {
        var lines = new Gee.ArrayList<Line> ();
        var loop = new MainLoop ();
        body.foreach_line.begin (
            line => lines.add (line),
            new Cancellable (),
            (obj, res) => {
                body.foreach_line.end (res);
                loop.quit ();
            }
        );
        loop.run ();
        return lines.to_array ();
    }

    public static Line expected_text_line (string content) {
        return new Line (content, LineType.TEXT);
    }

    public static void assert_line_arrays (Line[]? actual, Line[]? expected, string field_name = "") {
        if (actual == null && expected != null) {
            error ("Expected %s field not to be null but it was\n", field_name);
        }

        if (actual != null && expected == null) {
            error ("Expected %s field to be null but it wasn't\n", field_name);
        }

        if (actual.length != expected.length) {
            error ("Expected %s field to have %d elements but it had %d\n", field_name, expected.length, actual.length);
        }

        for (int i = 0; i < actual.length; i++) {
            assert_line_eq (actual[i], expected[i], "%s[%d]".printf (field_name, i));
        }
    }

    public static void assert_line_eq (Line? actual, Line? expected, string field_name = "") {
        if (actual == null && expected != null) {
            error ("Expected %s field not to be null but it was\n", field_name);
        }

        if (actual != null && expected == null) {
            error ("Expected %s field to be null but it wasn't\n", field_name);
        }

        assert_str_eq (actual.content, expected.content, "%s.content".printf (field_name));
        assert_line_type_eq (actual.line_type, expected.line_type, "%s.line_type".printf (field_name));
    }

    public static void assert_line_type_eq (LineType? actual, LineType? expected, string field_name = "") {
        if (actual == null && expected != null) {
            error ("Expected %s field not to be null but it was\n", field_name);
        }

        if (actual != null && expected == null) {
            error ("Expected %s field to be null but it wasn't\n", field_name);
        }

        if (actual != expected) {
            error ("Expeted field %s to be %d, but was %d\n", field_name, expected, actual);
        }
    }

}
