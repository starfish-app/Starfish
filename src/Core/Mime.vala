public class Starfish.Core.Mime : Object {

    public string raw { get; construct; }

    public string main_type { get; private set; }
    public string sub_type { get; private set; }
    public string charset { get; private set; default = "utf-8"; }
    public string[] langs { get; private set; default = {}; }

    public bool is_text { get { return main_type == "text"; } }
    public bool is_gemtext {
        get { return main_type == "text" && sub_type == "gemini"; }
    }

    public Mime(string raw_mime) {
        Object (raw: raw_mime);
    }

    construct {
        var segments = raw.strip ().split (";");
        var types = segments[0].strip ().split ("/");
        main_type = types[0].strip ().ascii_down ();
        sub_type = types[1].strip ().ascii_down ();
        foreach (var segment in segments[1:segments.length]) {
            if (segment == null) {
                continue;
            }
            var key_val = segment.strip ().split ("=");
            if (key_val.length != 2) {
                continue;
            }
            var key = key_val[0];
            var val = key_val[1];
            if (key == null || val == null) {
                continue;
            }
            if (key.strip ().ascii_down () == "charset") {
                charset = val.strip ().ascii_down ();
            }
            if (key.strip ().ascii_down () == "lang") {
                langs = val.strip ().split (",");
                for (var i = 0; i < langs.length; i++) {
                    langs[i] = langs[i].strip ();
                }
            }
        }
    }

    public string to_string () {
        return "%s/%s".printf (main_type, sub_type);
    }
}
