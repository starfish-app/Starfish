public class Starfish.UI.PageTextView : Gtk.Overlay, ResponseView {

    public Core.Session session { get; construct; }
    private Cancellable cancel;
    private GemtextView gemtext_view;

    public PageTextView (Core.Session session) {
        Object (session: session);
    }

    public signal void link_event (LinkEvent event);

    construct {
        cancel = new Cancellable ();
        session.cancel_loading.connect (() => {
            cancel.cancel ();
        });

        gemtext_view = new GemtextView (session) {
            top_margin = 16,
            left_margin = 24,
            right_margin = 24
        };

        add (gemtext_view);
        gemtext_view.link_event.connect ((v, event) => link_event (event));
    }

    public virtual bool can_display (Core.Response response) {
        if (!response.is_success) {
            return false;
        }

        var mime = response.mime ();
        if (mime == null) {
            return false;
        }

        return mime.is_text;
    }

    public virtual void clear () {
        gemtext_view.clear ();
    }

    public virtual void display (Core.Response response) {
        cancel.reset ();
        var body = response.text_body ();
        clear ();
        body.foreach_line.begin (gemtext_view.display_line, cancel, (obj, res) => {
            body.foreach_line.end (res);
            session.loading = false;
            cancel.reset ();
            response.close ();
        });
    }

    // TODO: refactor other code to use GemtextView directly
    // and then remove this method:
    public void display_line (Core.Line line) {
        gemtext_view.display_line (line);
    }

    public unowned Gdk.Window? get_window (Gtk.TextWindowType win) {
        return gemtext_view.get_window (win);
    }
}

