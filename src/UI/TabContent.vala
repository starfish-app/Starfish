public class Starfish.UI.TabContent : Gtk.Box {

    private ContentStack content;

    public Window window { get; construct; }
    public Core.Tab tab_model { get; construct; }

    public TabContent (Window window, Core.Tab tab_model) {
        Object (
            window: window,
            tab_model: tab_model
        );
    }

    construct {
        var session = tab_model.session;

        var input_view = new InputView (session);
        input_view.submit.connect (on_input_submit);
        var text_view = new PageTextView (session);
        text_view.link_event.connect (on_link_event);
        var error_view = new PageErrorView (session);
        error_view.link_event.connect (on_link_event);
        var image_view = new PageImageView (session);
        var download_view = new PageDownloadView (session);
        content = new ContentStack.with_views (
            "text-response", text_view,
            "error-response", error_view,
            "input", input_view,
            "image", image_view,
            "download", download_view
        );

        var grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        grid.add (content);
        this.add (grid);

        session.notify["loading"].connect ((s, p) => {
            if (session.loading) {
                content.clear ();
            }
        });

        session.response_received.connect (response => {
            content.display (response);
        });

        session.init ();
    }

    private void on_input_submit (InputView view, string input) {
        var query = "?" + Core.Uri.encode (input);
        tab_model.session.navigate_to (query);
    }

    private void on_link_event (PageTextView page, LinkEvent event) {
        switch (event.event_type) {
            case LinkEventType.HOVER_ENTER:
                var gdk_window = page.get_window (Gtk.TextWindowType.TEXT);
                if (gdk_window != null) {
                    var pointer = new Gdk.Cursor.from_name (
                        gdk_window.get_display (),
                        "pointer"
                    );

                    gdk_window.set_cursor (pointer);
                }

                return;
            case LinkEventType.HOVER_EXIT:
                var gdk_window = page.get_window (Gtk.TextWindowType.TEXT);
                if (gdk_window != null) {
                    var text = new Gdk.Cursor.from_name (
                        gdk_window.get_display (),
                        "text"
                    );

                    gdk_window.set_cursor (text);
                }

                return;
            case LinkEventType.LEFT_MOUSE_CLICK:
                var raw_uri = event.link_url;
                tab_model.session.navigate_to (raw_uri);
                return;
        }
    }
}

