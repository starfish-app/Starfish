public abstract class Starfish.Templates.Template : Object {

    protected abstract string get_template ();

    public string render (string? param_key = null, string? param_value = null, ...) {
        var result = get_template ();
        if (param_key != null && param_value != null) {
            var key = "${%s}".printf (param_key);
            result = result.replace (key, param_value);
        }

        var l = va_list ();
        while (true) {
            string? next_param_key = l.arg ();
            if (next_param_key == null) {
                break;
            }

            string? next_param_value = l.arg ();
            if (next_param_value == null) {
                continue;
            }

            var key = "${%s}".printf (next_param_key);
            result = result.replace (key, next_param_value);
        }

        return result;
    }
}

