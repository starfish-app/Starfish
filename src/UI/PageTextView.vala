public class Starfish.UI.PageTextView : Gtk.TextView, ResponseView {

    public Core.Session session { get; construct; }
    private Gee.Map<int, LinkDetails> LINE_TO_LINK = new Gee.HashMap<int, LinkDetails> ();
    private LinkDetails? hovering_over_link = null;
    private Cancellable cancel;

    public PageTextView (Core.Session session) {
        Object (
            session: session,
            editable: false,
            cursor_visible: false,
            top_margin: 16,
            left_margin: 24,
            right_margin: 24,
            wrap_mode: Gtk.WrapMode.WORD_CHAR
        );
    }

    private const string H1 = "h1";
    private const string H2 = "h2";
    private const string H3 = "h3";
    private const string LINK = "link";
    private const string QUOTE= "quote";
    private const string TEXT = "text";
    private const string LIST = "list";
    private const string PREFORMATTED = "preformatted";

    private static Gee.Map<Core.LineType, string> TYPE_TO_TAG = new Gee.HashMap<Core.LineType, string> ();

    public signal void link_event (LinkEvent event);

    static construct {
        TYPE_TO_TAG[Core.LineType.HEADING_1] = H1;
        TYPE_TO_TAG[Core.LineType.HEADING_2] = H2;
        TYPE_TO_TAG[Core.LineType.HEADING_3] = H3;
        TYPE_TO_TAG[Core.LineType.LINK] = LINK;
        TYPE_TO_TAG[Core.LineType.QUOTE] = QUOTE;
        TYPE_TO_TAG[Core.LineType.TEXT] = TEXT;
        TYPE_TO_TAG[Core.LineType.LIST_ITEM] = LIST;
        TYPE_TO_TAG[Core.LineType.PREFORMATTED] = PREFORMATTED;
    }

    construct {
        cancel = new Cancellable ();
        session.cancel_loading.connect (() => {
            cancel.cancel ();
        });

        this.buffer.create_tag (
            H1,
            scale: Pango.Scale.XX_LARGE,
            variant: Pango.Variant.SMALL_CAPS
        );

        this.buffer.create_tag (
            H2,
            scale: Pango.Scale.X_LARGE,
            variant: Pango.Variant.SMALL_CAPS
        );

        this.buffer.create_tag (
            H3,
            scale: Pango.Scale.LARGE,
            variant: Pango.Variant.SMALL_CAPS
        );

        var link_tag = this.buffer.create_tag (
            LINK,
            underline: Pango.Underline.LOW,
            pixels_below_lines: 4,
            foreground_rgba: session.theme.link_color,
            foreground_set: true
        );

        var quote_tag = this.buffer.create_tag (
            QUOTE,
            style: Pango.Style.ITALIC,
            left_margin: 36,
            paragraph_background_rgba: session.theme.block_background_color,
            paragraph_background_set: true
        );

        var monospace_tag = this.buffer.create_tag (
            PREFORMATTED,
            family: "Monospace",
            wrap_mode: Gtk.WrapMode.NONE,
            paragraph_background_rgba: session.theme.block_background_color,
            paragraph_background_set: true
        );

        this.buffer.create_tag (
            TEXT,
            indent: 8
        );

        this.buffer.create_tag (
            LIST,
            left_margin: 36
        );

        get_style_context ().add_provider (
            session.theme.get_gemtext_css(),
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        session.theme.notify.connect (() => {
            link_tag.foreground_rgba = session.theme.link_color;

            get_style_context ().add_provider (
                session.theme.get_gemtext_css(),
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        });

        this.motion_notify_event.connect ((view, event) => on_motion_notify (event));
        this.button_release_event.connect ((view, event) => this.on_button_release (event));
    }

    private bool on_motion_notify (Gdk.EventMotion event) {
        var link = link_for_event (event.x, event.y);
        if (link != null) {
            if (this.hovering_over_link != link) {
                if (this.hovering_over_link != null) {
                    var exit_event = new LinkEvent (
                        this.hovering_over_link.url,
                        this.hovering_over_link.desc,
                        LinkEventType.HOVER_EXIT
                    );

                    this.link_event (exit_event);
                }
                var enter_event = new LinkEvent (
                    link.url,
                    link.desc,
                    LinkEventType.HOVER_ENTER
                );

                this.hovering_over_link = link;
                this.link_event (enter_event);
            }
        } else if (this.hovering_over_link != null) {
            var exit_event = new LinkEvent (
                this.hovering_over_link.url,
                this.hovering_over_link.desc,
                LinkEventType.HOVER_EXIT
            );

            this.hovering_over_link = null;
            this.link_event (exit_event);
        }

        return false;
    }

    private bool on_button_release (Gdk.EventButton event) {
        var link = link_for_event (event.x, event.y);
        if (link != null) {
            LinkEventType? type = null;
            switch (event.button) {
                case 1:
                    type = LinkEventType.LEFT_MOUSE_CLICK;
                    break;
                case 2:
                    type = LinkEventType.MIDDLE_MOUSE_CLICK;
                    break;
                case 3:
                    type = LinkEventType.RIGHT_MOUSE_CLICK;
                    break;
            }

            if (type != null) {
                var l_event = new LinkEvent (link.url, link.desc, type);
                this.link_event (l_event);
                return true;
            }
        }

        return false;
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
        buffer.text = "";
        LINE_TO_LINK.clear ();
    }

    public virtual void display (Core.Response response) {
        cancel.reset ();
        var body = response.text_body ();
        clear ();
        body.foreach_line.begin (display_line, cancel, (obj, res) => {
            body.foreach_line.end (res);
            session.loading = false;
            cancel.reset ();
            response.close ();
        });
    }

    protected void display_line (Core.Line line) {
        Gtk.TextIter end;
        this.buffer.get_end_iter (out end);
        var text = line.get_display_content () + "\n";
        if (line.line_type == Core.LineType.LIST_ITEM) {
            text = "• " + text;
        } else if (line.line_type == Core.LineType.LINK) {
            var details = new LinkDetails (line.get_url (), line.get_url_desc ());
            LINE_TO_LINK[end.get_line ()] = details;
            try {
                var uri = Core.Uri.parse (line.get_url (), session.current_uri);
                if (uri.scheme == "gemini") {
                    text = "♊️ " + text;
                } else if (uri.scheme == "file") {
                    text = "📄️ " + text;
                } else {
                    text = "🌐 " + text;
                }
            } catch (Core.UriError e) {}
        }

        var tag = TYPE_TO_TAG[line.line_type];
        if (tag != null) {
            this.buffer.insert_with_tags_by_name (ref end, text, -1, tag);
        }
    }

    private LinkDetails? link_for_event (double event_x, double event_y) {
        int buffer_x;
        int buffer_y;
        this.window_to_buffer_coords (
            Gtk.TextWindowType.TEXT,
            (int) event_x,
            (int) event_y,
            out buffer_x,
            out buffer_y
        );
        Gtk.TextIter iter;
        this.get_iter_at_location (out iter, buffer_x, buffer_y);
        var tags = iter.get_tags ();
        foreach (var tag in tags) {
            if (tag.name == LINK) {
                var line = iter.get_line ();
                return LINE_TO_LINK[line];
            }
        }
        return null;
    }
}

private class Starfish.LinkDetails : Object {
    public string url { get; construct; }
    public string desc { get; construct; }

    public LinkDetails (string url, string desc) {
        Object (url: url, desc: desc);
    }
}

