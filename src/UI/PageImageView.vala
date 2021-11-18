public class Starfish.UI.PageImageView : Gtk.Grid, ResponseView {

    public Core.Session session { get; construct; }
    public Gee.Set<string> supported_mime_types { get; construct; }

    private IOStream connection;
    private Gtk.Image image;
    private Gdk.Pixbuf original_pixbuf;
    private Cancellable cancel;

    public PageImageView (Core.Session session) {
        Object (
            session: session,
            supported_mime_types: find_supported_types (),
            orientation: Gtk.Orientation.VERTICAL
        );
    }

    construct {
        cancel = new Cancellable ();
        session.cancel_loading.connect (() => {
            cancel.cancel ();
        });

        image = new Gtk.Image ();
        var scrollable = new Gtk.ScrolledWindow (null, null) {
            vexpand = true,
            hexpand = true
        };

        scrollable.add (image);
        attach (scrollable, 0, 0);
    }

    public void clear () {
        image.clear ();
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
        try {
            cancel.reset ();
            var type = response.mime ().to_string ();
            var loader = new Gdk.PixbufLoader.with_mime_type (type);
            loader.area_prepared.connect ((l) => {
                original_pixbuf = loader.get_pixbuf ();
            });

            loader.area_updated.connect ((l, x, y, w, h) => {
                image.set_from_pixbuf (original_pixbuf);
            });

            connection = response.connection;
            var stream = connection.input_stream;
            var buffered_stream = new BufferedInputStream (stream);
            read_into_loader.begin (buffered_stream, loader, (obj, res) => {
                read_into_loader.end (res);
                session.loading = false;
                cancel.reset ();
                response.close ();
            });
        } catch (Error e) {
            print ("Error: %s\n", e.message);
        }
    }

    private async void read_into_loader (BufferedInputStream input, Gdk.PixbufLoader loader) {
        try {
            uint8 buffer[1000];
            ssize_t size;
            while ((size = yield input.read_async (buffer, Priority.HIGH, cancel)) > 0) {
                loader.write (buffer[0:size]);
                if (cancel.is_cancelled ()) {
                    break;
                }
            }

            loader.close ();
        } catch (Error e) {
            warning ("Error reading from connection input into Pixbuf loader. Error:  %s", e.message);
        }
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

