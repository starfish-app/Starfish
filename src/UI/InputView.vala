public class Starfish.UI.InputView : Gtk.Grid, ResponseView {

    public Core.Session session { get; construct; }
    private Gtk.Label prompt;
    private Gtk.TextView input;
    private TextViewHighlighter highlighter;
    private Gtk.Label length_label;
    private Gtk.Label validation_error;
    private Gtk.Button send;
    private string? uri_str;

    private const int MAX_LEN = 1024;

    public InputView (Core.Session session) {
        Object (
            session: session,
            orientation: Gtk.Orientation.VERTICAL,
            margin_top: 16,
            margin_left: 24,
            margin_right: 24,
            row_spacing: 4,
            column_spacing: 4
        );
    }

    construct {
        var heading = new Gtk.Label (_("Input")) {
            halign = Gtk.Align.START,
            wrap = true,
            selectable = true,
            margin_bottom = 8,
        };

        heading.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        attach (heading, 0, 1, 2, 1);

        prompt = new Gtk.Label ("") {
            halign = Gtk.Align.START,
            wrap = true,
            selectable = true,
            margin_bottom = 8,
        };

        attach_next_to (prompt, heading, Gtk.PositionType.BOTTOM, 2, 1);

        input = new Gtk.TextView () {
            editable = true,
            cursor_visible = true,
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            hexpand = true,
            vexpand = true,
            bottom_margin = 8,
            left_margin = 8,
            right_margin = 8,
            top_margin = 8,
        };

        input.buffer.changed.connect (on_input_change);
        var spell = new GtkSpell.Checker ();
        spell.attach (input);
        var scrollable = new Gtk.ScrolledWindow (null, null);
        scrollable.add (input);
        highlighter = new TextViewHighlighter (scrollable);
        attach_next_to (highlighter, prompt, Gtk.PositionType.BOTTOM, 2, 20);

        var initial_uri_str = session.current_uri.to_string ();
        length_label = new Gtk.Label (input_size_label_txt ()) {
            selectable = true,
        };

        var info_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("dialog-information"),
            pixel_size = 16,
            tooltip_text = _("Because of the way input is defined in Gemini a single character you type might take up more than one space.")
        };

        var size_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4) {
            halign = Gtk.Align.START,
        };

        size_box.add (length_label);
        size_box.add (info_icon);
        attach_next_to (size_box, highlighter, Gtk.PositionType.BOTTOM, 1, 1);

        validation_error = new Gtk.Label ("") {
            selectable = true,
            halign = Gtk.Align.END
        };

        validation_error.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);
        attach_next_to (validation_error, size_box, Gtk.PositionType.RIGHT, 1, 1);

        send = new Gtk.Button.with_label (_("Send")) {
            sensitive = false,
            halign = Gtk.Align.END,
            margin_top = 12,
            always_show_image = true,
            image_position = Gtk.PositionType.RIGHT,
        };

        send.get_style_context ().add_class (
            Gtk.STYLE_CLASS_SUGGESTED_ACTION
        );

        send.clicked.connect (on_submit);
        attach_next_to (send, size_box, Gtk.PositionType.BOTTOM, 2, 1);
    }

    public signal void submit (string uri_str);

    public bool can_display (Core.Response response) {
        return response.is_input;
    }

    public void clear () {
        prompt.label = "";
        input.buffer.text = "";
        validation_error.label = "";
        send.sensitive = false;
        highlighter.error = false;
    }

    public void display (Core.Response response) {
        prompt.label = response.meta ?? _("Please provide input.");
        input.input_purpose = response.status != 11 ? Gtk.InputPurpose.FREE_FORM : Gtk.InputPurpose.PASSWORD;
        length_label.label = input_size_label_txt ();
        update_send_button ();
        session.loading = false;
    }

    private void on_submit (Gtk.Widget ignored) {
        if (uri_str != null) {
            submit (uri_str);
        } else {
            warning ("Tried to submit empty input! This is probably a bug because validation should prevent this.");
        }
    }

    private void on_input_change () {
        uri_str = uri_with_input_query ();
        length_label.label = input_size_label_txt (uri_str);
        if (uri_str != null && uri_str.length <= MAX_LEN) {
            send.sensitive = true;
            highlighter.error = false;
            validation_error.label = "";
        } else {
            send.sensitive = false;
            highlighter.error = true;
            if (uri_str == null) {
                validation_error.label = _("Please provide some input.");
            } else {
                validation_error.label = _("Input size exceeds maximum size. Please shorten your input.");
            }
        }
    }

    private string input_size_label_txt (string? str = null) {
        int len;
        if (str != null) {
            len = str.length;
        } else {
            var default_uri_str = session.current_uri.to_string () + "?";
            len = default_uri_str.length;
        }

        return _("Total input size: %d/%d").printf (len, MAX_LEN);
    }

    private string? uri_with_input_query () {
        var input_txt = input.buffer.text;
        if (input_txt == null || input_txt.length == 0) {
            return null;
        }

        var query = "?" + Core.Uri.encode (input_txt);
        try {
            var uri = Core.Uri.parse (query, session.current_uri);
            return uri.to_string ();
        } catch (Core.UriError e) {
            warning ("Failed to encode Uri for input %s", input_txt);
            return null;
        }
    }

    private void update_send_button () {
        var client_cert = session.client_cert_info;
        if (client_cert != null) {
            var cert_name = client_cert.common_name;
            var uri = session.current_uri.to_string ();
            send.label = _("Send with identity");
            send.tooltip_text = _("You are currently using your %s identity. The page at %s may associate the input you provide with this identity.").printf (cert_name ?? _("unnamed"), uri);
            send.image = new Gtk.Image () {
                icon_name = "avatar-default-symbolic",
                icon_size = Gtk.IconSize.BUTTON,
                margin_left = 4,
            };

            send.image.show_all ();
        } else {
            send.label = _("Send");
            send.tooltip_text = null;
            send.image = null;
        }
    }
}

