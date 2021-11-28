public class Starfish.Core.Line : Object {

    public string content { get; construct; }
    public LineType line_type { get; construct; }

    public Line (string content, LineType line_type) {
        Object (content: content, line_type: line_type);
    }

    public string? get_url () {
        if (line_type != LineType.LINK) {
            return null;
        }

        var clean_content = content.delimit ("\t", ' ');
        var without_prefix = clean_content[2:clean_content.length].strip ();
        var segments = without_prefix.split (" ", 2);
        return segments[0];
    }

    public string? get_url_desc () {
        if (line_type != LineType.LINK) {
            return null;
        }

        var clean_content = content.delimit ("\t", ' ');
        var without_prefix = clean_content[2:clean_content.length].strip ();
        var segments = without_prefix.split (" ", 2);
        if (segments.length == 1) {
            return segments[0];
        }

        return segments[1].strip ();
    }

    public string? get_alt_text () {
        if (line_type != LineType.PREFORMATTED_START) {
            return null;
        }

        if (content.length > 3) {
            return content.slice (3, content.length);
        }

        return "";
    }

    public string get_display_content () {
        switch (line_type) {
            case LineType.LINK:
                return get_url_desc ();
            case LineType.PREFORMATTED_START:
                return "";
            case LineType.PREFORMATTED_END:
                return "";
            case LineType.LIST_ITEM:
                return content.slice (2, content.length);
            case LineType.QUOTE:
                return content.slice (1, content.length);
            case LineType.HEADING_1:
                return content.slice (1, content.length).strip ();
            case LineType.HEADING_2:
                return content.slice (2, content.length).strip ();
            case LineType.HEADING_3:
                return content.slice (3, content.length).strip ();
            default:
                return content;
        }
    }
}

