public class Starfish.UI.PageTextView : Gtk.Grid, ResponseView {

    public Core.Session session { get; construct; }
    private Cancellable cancel;
    private Gtk.Overlay overlay;
    private GemtextView gemtext_view;
    private GemtextSearchBar search_bar;
    private Granite.Widgets.OverlayBar? link_overlay;
    private TableOfContent toc;
    private Binding search_mode_binding;

    public PageTextView (Core.Session session) {
        Object (
            session: session,
            orientation: Gtk.Orientation.VERTICAL
        );
    }

    ~PageTextView () {
        search_mode_binding.unbind ();
    }

    public signal void link_event (LinkEvent event);

    construct {
        cancel = new Cancellable ();
        session.cancel_loading.connect (() => {
            cancel.cancel ();
        });

        overlay = new Gtk.Overlay () {
            hexpand = true,
            vexpand = true
        };

        gemtext_view = new GemtextView (session.theme, session.current_uri) {
            top_margin = 16,
            left_margin = 24,
            right_margin = 24
        };

        var scrollable = new Gtk.ScrolledWindow (null, null) {
            vexpand = true
        };

        scrollable.add (gemtext_view);
        scrollable.show ();
        overlay.add (scrollable);
        gemtext_view.link_event.connect (on_link_event);
        toc = new TableOfContent (gemtext_view.scroll_to);
        overlay.add_overlay (toc);
        attach (overlay, 0, 0);

        search_bar = new GemtextSearchBar (gemtext_view);
        search_mode_binding = session.bind_property (
            "search_is_open",
            search_bar,
            "search_mode_enabled",
            BindingFlags.BIDIRECTIONAL
        );

        attach (search_bar, 0, 1);
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
        on_link_hover_exit ();
        search_bar.clear ();
        search_bar.search_mode_enabled = false;
        gemtext_view.clear ();
        toc.clear ();
        toc.hide ();
    }

    public virtual void display (Core.Response response) {
        cancel.reset ();
        var body = response.text_body ();
        clear ();
        gemtext_view.current_uri = session.current_uri;
        if (response.mime ().is_gemtext) {
            toc.show ();
        }

        body.foreach_line.begin (display_line, cancel, (obj, res) => {
            body.foreach_line.end (res);
            session.loading = false;
            cancel.reset ();
            response.close ();
        });
    }

    private void display_line (Core.Line line) {
        var line_ref = gemtext_view.display_line (line);
        if (line_ref != null) {
            toc.add_ref (line_ref, line);
        }
    }

    private void on_link_event (GemtextView view, LinkEvent event) {
        switch (event.event_type) {
            case LinkEventType.HOVER_ENTER:
                on_link_hover_enter (event.link_url);
                break;
            case LinkEventType.HOVER_EXIT:
                on_link_hover_exit ();
                break;
            case LinkEventType.LEFT_MOUSE_CLICK:
            case LinkEventType.MIDDLE_MOUSE_CLICK:
            case LinkEventType.RIGHT_MOUSE_CLICK:
                // noop
                break;
        }

        link_event (event);
    }

    private void on_link_hover_enter (string link_url) {
        if (link_overlay == null) {
            link_overlay = new Granite.Widgets.OverlayBar (overlay);
        }

        link_overlay.label = link_url;
        link_overlay.show_all ();
    }

    private void on_link_hover_exit () {
        if (link_overlay == null) {
            return;
        }

        link_overlay.label = null;
        link_overlay.hide ();
    }
}

