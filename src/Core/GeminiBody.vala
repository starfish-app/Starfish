public class Starfish.Core.GeminiBody : TextBody {

    public bool is_in_preformatted_block { get; protected set; default = false; }

    public GeminiBody.from_string (owned string content) {
        var mime = new Mime ("text/gemini");
        var conn = Response.in_mem_conn (content);
        this (mime, conn);
    }

    public GeminiBody (Mime mime, owned IOStream connection) {
        base (mime, connection);
    }

    // Must be invoker exacktly once per row!
    protected override LineType guess_type (string row) {
        if (row.length == 0) {
            if (is_in_preformatted_block) {
                return LineType.PREFORMATTED;
            }
            return LineType.TEXT;
        }

        if (is_preformatted_start (row)) {
            return LineType.PREFORMATTED_START;
        }

        if (is_preformatted_end (row)) {
            return LineType.PREFORMATTED_END;
        }

        if (is_in_preformatted_block) {
            return LineType.PREFORMATTED;
        }

        if (is_link (row)) {
            return LineType.LINK;
        }

        if (is_heading_1 (row)) {
            return LineType.HEADING_1;
        }

        if (is_heading_2 (row)) {
            return LineType.HEADING_2;
        }

        if (is_heading_3 (row)) {
            return LineType.HEADING_3;
        }

        if (is_list_item (row)) {
            return LineType.LIST_ITEM;
        }

        if (is_quote (row)) {
            return LineType.QUOTE;
        }

        return LineType.TEXT;
    }

    private bool is_link (string row) {
        var is_link = row.has_prefix ("=>") && row.strip ().length > 2;
        return is_link && !is_in_preformatted_block;
    }

    private bool is_preformatted_start (string row) {
        var result = !is_in_preformatted_block && row.has_prefix ("```");
        if (result) {
            is_in_preformatted_block = true;
        }
        return result;
    }

    private bool is_preformatted_end (string row) {
        var result = is_in_preformatted_block && row.has_prefix ("```");
        if (result) {
            is_in_preformatted_block = false;
        }
        return result;
    }

    private bool is_heading_1 (string row) {
        var starts_ok = row.has_prefix ("#");
        var is_not_h2 = row.length > 1 && row[1] != '#';
        return starts_ok && is_not_h2 && !is_in_preformatted_block;
    }

    private bool is_heading_2 (string row) {
        var starts_ok = row.has_prefix ("##");
        var is_not_h3 = row.length > 2 && row[2] != '#';
        return starts_ok && is_not_h3 && !is_in_preformatted_block;
    }

    private bool is_heading_3 (string row) {
        return row.has_prefix ("###") && !is_in_preformatted_block;
    }

    private bool is_list_item (string row) {
        return row.has_prefix ("* ") && !is_in_preformatted_block;
    }

    private bool is_quote (string row) {
        return row.has_prefix (">") && !is_in_preformatted_block;
    }
}

