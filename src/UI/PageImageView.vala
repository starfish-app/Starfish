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
            selectable = true,
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
        try {
            File file;
            var file_out = file_out_stream (response, out file);

            file_out.splice_async.begin (
                response.connection.input_stream,
                OutputStreamSpliceFlags.CLOSE_SOURCE | OutputStreamSpliceFlags.CLOSE_TARGET,
                Priority.HIGH,
                cancel,
                (obj, res) => {
                    try {
                        file_out.splice_async.end (res);
                    } catch (Error e) {
                        warning ("Error splicing gemini res stream into temp file stream: %s", e.message);
                    }

                    session.loading = false;
                    cancel.reset ();
                    response.close ();

                    var ok = AppInfo.launch_default_for_uri (file.get_uri (), null);
                    if (!ok) {
                        warning ("Failed to open uri %s", file.get_uri ());
                    }

                    session.navigate_back ();
                }
            );
        } catch (Error err) {
            session.loading = false;
            cancel.reset ();
            response.close ();
            warning ("Failed to save and open image, error: %s", err.message);
        }
    }

    private OutputStream file_out_stream (Core.Response response, out File file) throws Error {
        var dir = Environment.get_user_special_dir (UserDirectory.DOWNLOAD);
        var filename = response.uri.file_name ();
        var extension = "." + response.mime ().sub_type;
        if (!filename.has_suffix (extension)) {
            filename += extension;
        }

        file = File.new_build_filename (dir, filename, null);
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

