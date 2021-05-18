public interface Starfish.TestBase : Object {

    public abstract string get_base_path ();
    public abstract Gee.Map<string, TestFunc> get_tests ();

    public static void assert_str_arrays (
        string[]? actual,
        string[]? expected,
        string field_name = ""
    ) {
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
            assert_str_eq (actual[i], expected[i], "%s[%d]".printf (field_name, i));
        }
    }

    public static void assert_str_eq (string? actual, string? expected, string field_name = "") {
        if (actual == null && expected != null) {
            error ("Expected %s field not to be null but it was\n", field_name);
        }

        if (actual != null && expected == null) {
            error ("Expected %s field to be null but it wasn't\n", field_name);
        }

        if (actual != expected) {
            error ("Expeted field %s to be `%s`, but was `%s`\n", field_name, expected, actual);
        }
    }

    public static void assert_int_eq (int? actual, int? expected, string field_name = "") {
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

    public static void assert_bool_eq (bool? actual, bool? expected, string field_name = "") {
        if (actual == null && expected != null) {
            error ("Expected %s field not to be null but it was\n", field_name);
        }

        if (actual != null && expected == null) {
            error ("Expected %s field to be null but it wasn't\n", field_name);
        }

        if (actual != expected) {
            error ("Expeted field %s to be %s, but was %s\n", field_name, expected.to_string (), actual.to_string ());
        }
    }
}

