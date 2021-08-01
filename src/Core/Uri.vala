public class Starfish.Core.Uri : Object {

    public string? scheme { get; set; default = ""; }
    public string? userinfo { get; set; default = null; }
    public string? host { get; set; default = ""; }
    public int port { get; set; default = -1; } // -1 stands for null
    public string? path { get; set; default = ""; }
    public string? query { get; set; default = null; }
    public string? fragment { get; set; default = null; }

    public Uri (
        string? scheme = "",
        string? userinfo = null,
        string? host = "",
        int port = -1, // -1 stands for null
        string? path = "",
        string? query = null,
        string? fragment = null
    ) {
        Object (
            scheme: scheme,
            userinfo: userinfo,
            host: host,
            port: port,
            path: path,
            query: query,
            fragment: fragment
        );
    }

    public static Uri parse (string raw, Uri base_uri = new Uri ("gemini")) throws UriError {
        var tokens = tokenize (raw);
        var relative_uri = create_relative_uri (tokens);
        var result = resolve (relative_uri, base_uri);
        return result;
    }

    private static MatchInfo tokenize (string raw) throws UriError {
        var uri_pattern = "^((?<scheme>[^:/?#]+):)?(//(?<authority>[^/?#]*|\\[[^\\]]*\\]))?(?<path>[^?#]*)(\\?(?<query>[^#]*))?(#(?<fragment>.*))?$";
        try {
            var regex = new Regex (uri_pattern);
            MatchInfo result;
            if (!regex.match (raw, 0, out result)) {
                var msg = "string `%s` does not match URI pattern %s".printf (raw, uri_pattern);
                throw new UriError.FAILED_TO_TOKENIZE (msg);
            }
            return result;
        } catch (RegexError e) {
            var msg = "string `%s` could not be tokenized because: %s".printf (raw, e.message);
            throw new UriError.FAILED_TO_TOKENIZE (msg);
        }
    }

    private static Uri create_relative_uri (MatchInfo matches) throws UriError {
        var scheme = parse_str (matches.fetch_named ("scheme"));
        string? userinfo = null;
        string rest;
        var authority = matches.fetch_named ("authority");
        var userinfo_and_rest = authority.split ("@", 2);
        if (userinfo_and_rest.length == 2) {
            userinfo = parse_str (userinfo_and_rest[0]);
            rest = userinfo_and_rest [1] ?? "";
        } else {
            rest = authority;
        }

        string? host = null;
        int port = -1;
        if (rest.has_prefix ("[")) {
            var limit = rest.last_index_of_char (']') + 1;
            host = parse_str (rest[0:limit]);
            port = parse_int (rest[limit:rest.length]);
        } else {
            var host_and_port = rest.split (":", 2);
            if (host_and_port.length == 2) {
                host = parse_str (host_and_port[0]);
                port = parse_int (host_and_port[1]);
            } else {
                host = rest;
            }
        }

        var path = parse_str (matches.fetch_named ("path"));
        var query = parse_str (matches.fetch_named ("query"));
        var fragment = parse_str (matches.fetch_named ("fragment"));

        return new Uri (
            scheme,
            userinfo,
            host,
            port,
            path,
            query,
            fragment
        );
    }

    private static Uri resolve (Uri r, Uri b) {
        var t = new Uri ();
        if (r.scheme != null && r.scheme.length > 0) {
            t.scheme = r.scheme;
            t.userinfo = r.userinfo;
            t.host = r.host;
            t.port = r.port;
            t.path = remove_dot_segments (r.path);
            t.query = r.query;
        } else {
            if (r.host != null && r.host.length > 0) {
                t.userinfo = r.userinfo;
                t.host = r.host;
                t.port = r.port;
                t.path = remove_dot_segments (r.path);
                t.query = r.query;
            } else {
                if (r.path == null || r.path == "") {
                    t.path = b.path;
                    if (r.query != null && r.query.length > 0) {
                        t.query = r.query;
                    } else {
                        t.query = b.query;
                    }

                } else {
                    if (r.path.has_prefix ("/")) {
                        t.path = remove_dot_segments (r.path);
                    } else {
                        t.path = merge (b, r.path);
                        t.path = remove_dot_segments (t.path);
                    }

                    t.query = r.query;
                }

                t.userinfo = b.userinfo;
                t.host = b.host;
                t.port = b.port;
            }

            t.scheme = b.scheme;
        }

        t.fragment = r.fragment;
        return t;
    }

    private static string? parse_str (string? s) {
        if (s != null && s.length > 0) {
            return s;
        }
        return null;
    }

    private static int parse_int (string? s) {
        if (s != null && s.length > 0) {
            var i = int.parse (s);
            return i;
        }
        return -1;
    }

    private static string remove_dot_segments (string? path) {
        if (path == null || path.length == 0) {
            return "";
        }
        string in_buff = path;
        string out_buff = "";

        while (in_buff.length > 0) {
            if (in_buff.has_prefix ("../")) {
                in_buff = in_buff[3:in_buff.length];
                continue;
            }

            if (in_buff.has_prefix ("./")) {
                in_buff = in_buff[2:in_buff.length];
                continue;
            }

            if (in_buff.has_prefix ("/./")) {
                in_buff = "/" + in_buff[3:in_buff.length];
                continue;
            }

            if (in_buff == "/.") {
                in_buff = "/" + in_buff [2:in_buff.length];
                continue;
            }

            if (in_buff.has_prefix ("/../")) {
                in_buff = "/" + in_buff[4:in_buff.length];
                var end = out_buff.last_index_of_char ('/');
                if (end > 0) {
                    out_buff = out_buff[0:end] ?? "";
                } else {
                    out_buff = "";
                }
                continue;
            }

            if (in_buff == "/..") {
                in_buff = "/" + in_buff[3:in_buff.length];
                var end = out_buff.last_index_of_char ('/');
                if (end > 0) {
                    out_buff = out_buff[0:end] ?? "";
                } else {
                    out_buff = "";
                }
                continue;
            }

            if (in_buff == "." || in_buff == "..") {
                in_buff = "";
                continue;
            }

            var end = in_buff.index_of_char  ('/', 1);
            if (end > 0) {
                out_buff += in_buff[0:end];
                in_buff = in_buff[end:in_buff.length];
            } else {
                out_buff += in_buff;
                in_buff = "";
            }
        }

        return out_buff;
    }

    private static string merge (Uri b, string r_path) {
        if (b.host != null && b.host.length > 0 && (b.path == null || b.path.length == 0)) {
            return "/%s".printf (r_path);
        }
        if (b.path != null && b.path.length > 0 && b.path.contains ("/")) {
            var slash_idx = b.path.last_index_of_char ('/');
            return "%s%s".printf (b.path[0:slash_idx + 1], r_path);
        }
        return r_path;
    }

    public static string encode (string? raw) {
        if (raw == null || raw.length == 0) {
            return raw;
        }

        var builder = new StringBuilder ();
        unichar c;
        for (int i = 0; raw.get_next_char (ref i, out c);) {
            if (c.isalnum () || c == '-' || c == '.' || c == '_' || c == '~') {
                builder.append_unichar (c);
            } else {
                builder.append ("%%%.2x".printf (c));
            }
        }

        return builder.str;
    }

    public string to_string () {
        var buff = new StringBuilder ();
        if (scheme != null && scheme.length > 0) {
            buff.append (scheme);
            buff.append (":");
        }

        if (host != null && host.length > 0) {
            if (userinfo != null && userinfo.length > 0) {
                buff.append (userinfo);
                buff.append ("@");
            }

            buff.append ("//");
            buff.append (host);

            if (port >= 0) {
                buff.append (":");
                buff.append (port.to_string ());
            }
        }

        if (path != null && path.length > 0) {
            buff.append (path);
        }

        if (query != null && query.length > 0) {
            buff.append ("?");
            buff.append (query);
        }

        if (fragment != null && fragment.length > 0) {
            buff.append ("#");
            buff.append (fragment);
        }

        return buff.str;
    }

    public InetAddress[] resolve_host () {
        if (host == null || host == "") {
            return {};
        }

        var resolver = Resolver.get_default ();
        try {
            var res_list = resolver.lookup_by_name (host);
            InetAddress[] res = {};
            foreach (var addr in res_list) {
                res += addr;
                return res;
            }
        } catch (Error ignored) {}
        return {};
    }

    public Uri one_up () {
        if (path_is_empty ()) {
            return root ();
        }

        var path_segments = path.split ("/");
        var new_path = "";
        foreach (var segment in path_segments[1:path_segments.length - 1]) {
                new_path += "/" + segment;
        }

        if (!path.has_suffix ("/")) {
            new_path = new_path + "/";
        }

        return new Uri (scheme, userinfo, host, port, new_path);
    }

    public Uri root () {
        if (!path.contains ("/~")) {
            return new Uri (scheme, userinfo, host, port);
        } else {
            var tldi = path.index_of_char ('~');
            var base_path = path[0:tldi];
            var user_path = path[tldi:path.length];
            if (!user_path.contains ("/")) {
                return this;
            }
            var username = user_path[0:user_path.index_of_char ('/')];
            var new_path = base_path + username;
            return new Uri (scheme, userinfo, host, port, new_path);
        }
    }

    public string? file_name () {
        if (path_is_empty () || path.replace ("/", "").length == 0) {
            return host;
        }

        return last_non_empty_path_segment ();
    }

    private string last_non_empty_path_segment () {
        var cleaned_up_path = path;
        while (cleaned_up_path.has_suffix ("/")) {
            cleaned_up_path = cleaned_up_path[0:cleaned_up_path.length - 1];
        }

        return cleaned_up_path[cleaned_up_path.last_index_of ("/") + 1:cleaned_up_path.length];
    }

    private bool path_is_empty () {
        return path == null || path == "" || path == "/";
    }
}

public errordomain Starfish.Core.UriError {
    FAILED_TO_TOKENIZE,
    NOT_IMPLEMENTED
}

