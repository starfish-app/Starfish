public class Starfish.UI.InputView : Gtk.Grid, ResponseView {

    public Core.Session session { get; construct; }
    private Gtk.Label prompt;
    private Gtk.Entry input;
    private Gtk.Button send;

    public InputView (Core.Session session) {
        Object (
            session: session,
            orientation: Gtk.Orientation.VERTICAL,
            halign: Gtk.Align.CENTER,
            margin_top: 16,
            margin_start: 24,
            margin_end: 24,
            row_spacing: 16,
            column_spacing: 8
        );
    }

    construct {
        prompt = new Gtk.Label ("");
        attach (prompt, 0, 0);
        input = new Gtk.Entry ();
        input.activate.connect (on_submit);
        input.changed.connect (on_input_change);
        attach (input, 0, 1);
        send = new Gtk.Button.with_label (_("Send"));
        send.sensitive = false;
        send.clicked.connect (on_submit);
        attach_next_to (send, input, Gtk.PositionType.RIGHT);
    }

    public signal void submit (string input);

    public bool can_display (Core.Response response) {
        return response.is_input;
    }

    public void clear () {
        prompt.label = "";
        input.text = "";
        send.sensitive = false;
    }

    public void display (Core.Response response) {
        prompt.label = response.meta ?? _("Please provide input.");
        session.loading = false;
    }

    private void on_submit (Gtk.Widget ignored) {
        var txt = input.text;
        if (txt != null && txt.length > 0) {
            submit (txt);
        }
    }

    private void on_input_change (Gtk.Editable ignored) {
        var txt = input.text;
        if (txt != null && txt.length > 0) {
            send.sensitive = true;
        } else {
            send.sensitive = false;
        }
    }
}
