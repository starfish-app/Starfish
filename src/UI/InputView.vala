public class Starfish.UI.InputView : Gtk.Grid, ResponseView {

    public Core.Session session { get; construct; }
    private Gtk.Label prompt;
    private Gtk.TextView input;
    private GtkSpell.Checker spell;
    private Gtk.Button send;

    public InputView (Core.Session session) {
        Object (
            session: session,
            orientation: Gtk.Orientation.VERTICAL,
            margin_top: 16,
            margin_left: 24,
            margin_right: 24,
            row_spacing: 16,
            column_spacing: 8
        );
    }

    construct {
        var heading = new Gtk.Label (_("Input")) {
            halign = Gtk.Align.START,
            wrap = true,
            selectable = true,
        };

        heading.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        attach (heading, 0, 1, 2, 1);

        prompt = new Gtk.Label ("") {
            halign = Gtk.Align.START,
            wrap = true,
            selectable = true,
        };

        attach_next_to (prompt, heading, Gtk.PositionType.BOTTOM, 2, 1);

        input = new Gtk.TextView () {
            editable = true,
            cursor_visible = true,
            hexpand = true,
            bottom_margin = 8,
            left_margin = 8,
            right_margin = 8,
            top_margin = 8,
        };

        input.buffer.changed.connect (on_input_change);
        attach_next_to (input, prompt, Gtk.PositionType.BOTTOM, 2, 8);

        spell = new GtkSpell.Checker ();
        spell.attach (input);

        send = new Gtk.Button.with_label (_("Send")) {
            sensitive = false,
            halign = Gtk.Align.END,
        };

        send.clicked.connect (on_submit);
        attach_next_to (send, input, Gtk.PositionType.BOTTOM, 2, 1);
    }

    public signal void submit (string input);

    public bool can_display (Core.Response response) {
        return response.is_input;
    }

    public void clear () {
        prompt.label = "";
        input.buffer.text = "";
        send.sensitive = false;
    }

    public void display (Core.Response response) {
        prompt.label = response.meta ?? _("Please provide input.");
        input.input_purpose = response.status != 11 ? Gtk.InputPurpose.FREE_FORM : Gtk.InputPurpose.PASSWORD;
        session.loading = false;
    }

    private void on_submit (Gtk.Widget ignored) {
        var txt = input.buffer.text;
        if (txt != null && txt.length > 0) {
            submit (txt);
        }
    }

    private void on_input_change () {
        var txt = input.buffer.text;
        if (txt != null && txt.length > 0) {
            send.sensitive = true;
        } else {
            send.sensitive = false;
        }
    }
}

