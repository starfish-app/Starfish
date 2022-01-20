public class Starfish.UI.PageImageView : Gtk.Grid, ResponseView {

    public Core.Session session { get; construct; }
    public Gee.Set<string> supported_mime_types { get; construct; }

    private Cancellable cancel;

    public PageImageView (Core.Session session) {
        Object (
            session: session,
            supported_mime_types: find_supported_types (),
            orientation: Gtk.Orientation.VERTICAL,
            margin_top: 16,
            margin_left: 24,
            margin_right: 24,
            row_spacing: 4,
            column_spacing: 4
        );
    }

    construct {
        cancel = new Cancellable ();
        session.cancel_loading.connect (() => {
            cancel.cancel ();
        });

        var heading = new Gtk.Label (_("Loading image...")) {
            halign = Gtk.Align.START,
            wrap = true,
            margin_bottom = 8,
        };

        heading.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        attach (heading, 0, 1, 2, 1);
    }

    public void clear () {
    }

    public bool can_display (Core.Response response) {
        if (!response.is_success) {
            return false;
        }

        var mime = response.mime ();
        if (mime == null) {
            return false;
        }

        return supported_mime_types.contains (mime.to_string ());
    }

    public void display (Core.Response response) {
        cancel.reset ();
        download_and_open.begin (response);
    }

    private async void download_and_open (Core.Response response) {
        try {
            File file;
            var file_out = file_out_stream (response, out file);

            yield file_out.splice_async (
                response.connection.input_stream,
                OutputStreamSpliceFlags.CLOSE_SOURCE | OutputStreamSpliceFlags.CLOSE_TARGET,
                Priority.HIGH,
                cancel
            );

            var ctx = get_window ().get_display ().get_app_launch_context ();
            yield AppInfo.launch_default_for_uri_async (
                file.get_uri (),
                ctx,
                cancel
            );
        } catch (Error err) {
            warning ("Failed to download file from %s, error: %s", response.uri.to_string (), err.message);
        } finally {
            session.loading = false;
            cancel.reset ();
            response.close ();
            session.navigate_back ();
        }
    }

    private OutputStream file_out_stream (Core.Response response, out File file) throws Error {
        var dir = Environment.get_user_cache_dir ();
        var filename = response.uri.file_name ();
        var extension = "." + response.mime ().sub_type;
        if (!filename.has_suffix (extension)) {
            filename += extension;
        }

        file = File.new_build_filename (dir, "tmp", filename);
        return file.replace (null, false, FileCreateFlags.REPLACE_DESTINATION);
    }

    private static Gee.Set<string> find_supported_types () {
        var supported_types = new Gee.HashSet<string> ();
        var supported_formats = Gdk.Pixbuf.get_formats ();
        foreach (var format in supported_formats) {
            foreach (var mime_type in format.get_mime_types ()) {
                supported_types.add (mime_type);
            }
        }

        return supported_types;
    }
}

