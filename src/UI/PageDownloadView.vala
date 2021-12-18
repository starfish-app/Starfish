public class Starfish.UI.PageDownloadView : Gtk.Grid, ResponseView {

    public Core.Session session { get; construct; }
    public string download_dir { get; construct; }

    private IOStream? connection;
    private string? file_type;
    private string? file_name;

    private Cancellable cancel;
    private bool is_downloading = false;
    private Gtk.Label title;
    private Gtk.Label subtitle;
    private Gtk.Button back_button;
    private Gtk.Button download_button;
    private Gtk.Label spinner_label;
    private Gtk.Spinner spinner;
    private Gtk.Label aborted_label;
    private Gtk.Button retry_button;
    private Gtk.Label finish_label;
    private Gtk.LinkButton show_file;

    public PageDownloadView (Core.Session session) {
        Object (
            session: session,
            download_dir: Environment.get_user_special_dir (UserDirectory.DOWNLOAD),
            orientation: Gtk.Orientation.VERTICAL,
            halign: Gtk.Align.CENTER,
            margin_top: 16,
            margin_start: 48,
            margin_end: 48,
            row_spacing: 16,
            column_spacing: 8
        );
    }

    construct {
        cancel = new Cancellable ();
        session.cancel_loading.connect (() => {
            cancel.cancel ();
            if (!is_downloading) {
                if (connection != null) {
                    connection.close ();
                }
                session.loading = false;
                show_retry_button ();
            }
        });

        orientation = Gtk.Orientation.VERTICAL;

        title = new Gtk.Label ("");
        attach (title, 0, 0, 2);

        subtitle = new Gtk.Label ("");
        attach (subtitle, 0, 1, 2);

        back_button = new Gtk.Button.with_label (_("Go Back")) {
            hexpand = false,
            halign = Gtk.Align.END
        };

        back_button.clicked.connect (() => {
            session.cancel_loading ();
            session.navigate_back ();
        });

        download_button = new Gtk.Button.with_label (_("Download")) {
            hexpand = false,
            halign = Gtk.Align.START
        };

        download_button.clicked.connect (do_download);

        spinner_label = new Gtk.Label (_("Downloading...")) {
            hexpand = false,
            halign = Gtk.Align.END
        };

        spinner = new Gtk.Spinner () {
            hexpand = false,
            halign = Gtk.Align.START
        };

        aborted_label = new Gtk.Label (_("Download aborted.")) {
            hexpand = false,
            halign = Gtk.Align.END
        };

        retry_button = new Gtk.Button.with_label (_("Retry")) {
            action_name = Window.ACTION_PREFIX + Window.ACTION_RELOAD,
            hexpand = false,
            halign = Gtk.Align.START
        };

        finish_label = new Gtk.Label (_("Download finished!")) {
            hexpand = false,
            halign = Gtk.Align.END
        };

        show_file = new Gtk.LinkButton.with_label ("", "Show Downloads") {
            hexpand = false,
            visited = false,
            halign = Gtk.Align.START,
            // I can't get to the actual location user picked in the native
            // file chooser, so offerig a "static" link that always opens
            // downloads dir is a best effort solution.
            uri = "file://%s".printf (download_dir)
        };
    }

    public void clear () {
        title.label = "";
        subtitle.label = "";
        spinner.stop ();
        remove_row (2);

        cancel.reset ();
        if (connection != null) {
            connection.close ();
        }
        connection = null;
        file_name = null;
        file_type = null;
    }

    public bool can_display (Core.Response response) {
        if (response.is_input) {
            return false;
        }

        if (!response.is_success) {
            return false;
        }

        var mime = response.mime ();
        if (mime == null) {
            return true;
        }

        return !mime.is_text;
    }

    public void display (Core.Response response) {
        show_download_buttons ();
        file_type = response.mime ().to_string ();
        file_name = response.uri.file_name () ?? "index";
        title.label = _("Cannot display %s").printf (file_name);
        subtitle.label = _("Starfish does not support %s content.\nDo you want to download %s instead?").printf (file_type, file_name);
        connection = response.connection;
    }

    private Gtk.FileChooserNative create_save_dialog () {
        var dialog = new Gtk.FileChooserNative (
            _("Save file"),
            null,
            Gtk.FileChooserAction.SAVE,
            _("Download"),
            _("Cancel")
        );

        dialog.do_overwrite_confirmation = true;
        dialog.set_current_folder (download_dir);
        dialog.set_current_name (file_name);
        return dialog;
    }

    private void show_download_buttons () {
        remove_row (2);
        attach (back_button, 0, 2);
        attach (download_button, 1, 2);
        show_all ();
    }

    private void show_spinner () {
        remove_row (2);
        attach (spinner_label, 0, 2);
        attach (spinner, 1, 2);
        spinner.start ();
        show_all ();
    }

    private void show_retry_button () {
        remove_row (2);
        attach (aborted_label, 0, 2);
        attach (retry_button, 1, 2);
        show_all ();
    }

    private void show_finish (string file_name) {
        remove_row (2);
        attach (finish_label, 0, 2);
        attach (show_file, 1, 2);
        show_all ();

        var notif = new Notification (_("Download finished!"));
        notif.set_body (_("Finished downloading %s.".printf (file_name)));
        notif.set_icon (new ThemedIcon ("process-completed"));
        var app = GLib.Application.get_default ();
        app.send_notification ("hr.from.josipantolis.starfish", notif);
    }

    private void do_download () {
        if (connection == null) {
            return;
        }

        var in_stream = connection.input_stream;
        var dialog = create_save_dialog ();
        if (dialog.run () == Gtk.ResponseType.ACCEPT) {
            show_spinner ();
            var file = File.new_for_uri (dialog.get_uri ());
            download_into.begin (in_stream, file, (obj, res) => {
                try {
                    download_into.end (res);
                } catch (Error e) {
                    warning ("Error saving file %s: %s", file_name, e.message);

                    connection.close ();
                    session.loading = false;
                    cancel.reset ();
                    show_retry_button ();
                    return;
                }

                connection.close ();
                session.loading = false;
                cancel.reset ();
                show_finish (file.get_basename ());
            });
        }
    }

    private async void download_into (InputStream in_stream, File file) throws Error {
        var out_stream = yield file.replace_async (
            null,
            false,
            FileCreateFlags.REPLACE_DESTINATION,
            Priority.HIGH,
            cancel
        );

        int buff_size = 100000;
        uint8[] buffer = new uint8[buff_size];
        size_t size;
        while (yield in_stream.read_all_async (buffer, Priority.HIGH, cancel, out size)) {
            yield out_stream.write_all_async (buffer[0:size], Priority.HIGH, cancel, out size);
            if (cancel.is_cancelled () || size < buff_size) {
                break;
            }
        }

        yield out_stream.flush_async (Priority.HIGH, cancel);
    }
}

