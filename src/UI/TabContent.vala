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
        var static_error_view = new PageStaticErrorView (session);
        var cert_error_view = new PageCertErrorView (session);
        var client_cert_picker_view = new PageClientCertPickerView (session, window);
        var image_view = new PageImageView (session);
        var download_view = new PageDownloadView (session);
        content = new ContentStack.with_views (
            "text-response", text_view,
            "error-response", static_error_view,
            "cert-error-response", cert_error_view,
            "client-cert-needed-response", client_cert_picker_view,
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

    private void on_input_submit (InputView view, string uri_str) {
        tab_model.session.navigate_to (uri_str);
    }

    private void on_link_event (PageTextView page, LinkEvent event) {
        switch (event.event_type) {
            case LinkEventType.LEFT_MOUSE_CLICK:
                var action_arg = new Variant.string (event.link_url);
                window.activate_action (Window.ACTION_LOAD_URI, action_arg);
                return;
            case LinkEventType.MIDDLE_MOUSE_CLICK:
                var action_args = new Variant.tuple ({
                    new Variant.string (event.link_url),
                    new Variant.boolean (false)
                });

                window.activate_action (Window.ACTION_LOAD_URI_IN_NEW_TAB, action_args);
                return;
        }
    }
}

