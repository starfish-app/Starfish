public class Starfish.Core.BookmarksManager : Object {

    public Templates.Template template { get; construct; }
    public File parent_dir { get; construct; }
    public File bookmarks_file { get; construct; }

    private Gee.Set<string> bookmarked_uris = new Gee.HashSet<string> ();

    public BookmarksManager (Templates.Template template = new Templates.Bookmarks ()) {
        var config_dir = Environment.get_user_config_dir ();
        Object (
            template: template,
            parent_dir: File.new_build_filename (config_dir, "starfish"),
            bookmarks_file: File.new_build_filename (config_dir, "starfish", "bookmarks.gmi")
        );
    }

    construct {
        recreate_missing_file.begin ((obj, res) => {
            try {
                recreate_missing_file.end (res);
                cache_bookmarked_uris.begin ();
            } catch (Error err) {
                warning ("Failed to create bookmarks file, error: %s", err.message);
            }
        });
    }

    public bool is_bookmarked (Uri uri) {
        return bookmarked_uris.contains (uri.to_string ());
    }

    public async void add_bookmark (Uri uri, string description = "") throws Error {
        yield recreate_missing_file ();
        var io_stream = yield bookmarks_file.open_readwrite_async (Priority.HIGH);
        io_stream.seek (0, SeekType.END);
        uint8[] content = "\n=> %s %s".printf (uri.to_string (), description).data;
        size_t written;
        yield io_stream.output_stream.write_all_async (content, Priority.HIGH, null, out written);
        bookmarked_uris.add (uri.to_string ());
    }

    public async void remove_bookmark (Uri uri) throws Error {
        yield recreate_missing_file ();
        var io_stream = yield bookmarks_file.open_readwrite_async (Priority.DEFAULT);
        var data_in_stream = new DataInputStream (io_stream.input_stream);
        string content = "";
        string? row = null;
        do {
            row = yield data_in_stream.read_line_utf8_async (Priority.HIGH);
            if (row != null) {
                var row_link = row_to_link (row);
                if (row_link != uri.to_string ()) {
                    content += row + "\n";
                }
            }
        } while (row != null);

        content = content.strip ();
        io_stream.seek (0, SeekType.SET);
        var out_stream = io_stream.output_stream;
        size_t bytes_written;
        yield out_stream.write_all_async (content.data, Priority.HIGH, null, out bytes_written);
        io_stream.truncate_fn ((int64) bytes_written);
        bookmarked_uris.remove (uri.to_string ());
    }

    public async Uri get_bookmarks_uri () throws Error {
        yield recreate_missing_file ();
        return Uri.parse (bookmarks_file.get_uri (), new Uri ("file"));
    }

    private async void recreate_missing_file () throws Error {
        if (!parent_dir.query_exists()) {
            parent_dir.make_directory_with_parents ();
        }

        if (!bookmarks_file.query_exists ()) {
            var out_stream = yield bookmarks_file.create_async (FileCreateFlags.NONE, Priority.HIGH);
            size_t written;
            var content = template.render (
                Templates.Bookmarks.PARENT_DIRECTORY_KEY,
                parent_dir.get_path ()
            ).data;

            yield out_stream.write_all_async (content, Priority.HIGH, null, out written);
        }
    }

    private async void cache_bookmarked_uris () {
        try {
            var in_stream = yield bookmarks_file.read_async (Priority.HIGH);
            var data_stream = new DataInputStream (in_stream);
            string? row = null;
            do {
                row = yield data_stream.read_line_utf8_async (Priority.HIGH);
                var row_link = row_to_link (row);
                if (row_link != null) {
                    bookmarked_uris.add (row_link);
                }
            } while (row != null);
        } catch (Error err) {
            warning ("Failed to read bookmarks file, error: %s", err.message);
        }
    }

    private string? row_to_link (string? row) {
        var is_link = row != null && row.has_prefix ("=>") && row.strip ().length > 2;
        if (!is_link) {
            return null;
        }

        var line = new Line (row, LineType.LINK);
        return line.get_url ();
    }
}

