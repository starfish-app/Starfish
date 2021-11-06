public class Starfish.UI.PageTextView : Gtk.Overlay, ResponseView {

    public Core.Session session { get; construct; }
    private Cancellable cancel;
    private GemtextView gemtext_view;
    private Granite.Widgets.OverlayBar? link_overlay;
    private TableOfContent toc;

    public PageTextView (Core.Session session) {
        Object (session: session);
    }

    public signal void link_event (LinkEvent event);

    construct {
        cancel = new Cancellable ();
        session.cancel_loading.connect (() => {
            cancel.cancel ();
        });

        gemtext_view = new GemtextView (session.theme, session.current_uri) {
            top_margin = 16,
            left_margin = 24,
            right_margin = 24
        };

        var scrollable = new Gtk.ScrolledWindow (null, null) {
            hexpand = true,
            vexpand = true
        };

        scrollable.add (gemtext_view);
        scrollable.show ();
        add (scrollable);
        gemtext_view.link_event.connect (on_link_event);
        toc = new TableOfContent (gemtext_view.scroll_to);
        add_overlay (toc);
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
        on_hover_exit ();
        gemtext_view.clear ();
        toc.clear ();
    }

    public virtual void display (Core.Response response) {
        cancel.reset ();
        var body = response.text_body ();
        clear ();
        gemtext_view.current_uri = session.current_uri;
        body.foreach_line.begin (display_line, cancel, (obj, res) => {
            body.foreach_line.end (res);
            session.loading = false;
            cancel.reset ();
            response.close ();
        });
    }

    // TODO: refactor other code to use GemtextView directly
    // and then make this method private:
    public void display_line (Core.Line line) {
        var line_ref = gemtext_view.display_line (line);
        if (line_ref != null) {
            toc.add_ref (line_ref, line);
        }
    }

    private void on_link_event (GemtextView view, LinkEvent event) {
        switch (event.event_type) {
            case LinkEventType.HOVER_ENTER:
                on_hover_enter (event.link_url);
                break;
            case LinkEventType.HOVER_EXIT:
                on_hover_exit ();
                break;
        }

        link_event (event);
    }

    private void on_hover_enter (string link_url) {
        if (link_overlay == null) {
            link_overlay = new Granite.Widgets.OverlayBar (this);
        }

        link_overlay.label = link_url;
        link_overlay.show_all ();
    }

    private void on_hover_exit () {
        if (link_overlay == null) {
            return;
        }

        link_overlay.label = null;
        link_overlay.hide ();
    }
}

