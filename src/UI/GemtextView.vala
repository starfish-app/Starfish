public class Starfish.UI.GemtextView : Gtk.TextView {

    public Core.Theme theme { get; construct; }
    public Core.Uri current_uri { get; set; }

    private Gtk.TextTag h1_tag;
    private Gtk.TextTag h2_tag;
    private Gtk.TextTag h3_tag;
    private Gtk.TextTag quote_tag;
    private Gtk.TextTag text_tag;
    private Gtk.TextTag list_item_tag;

    private string? last_alt_text = null;
    private GemtextRef last_inserted_ref = new GemtextRef ();
    private Gtk.TextTag? hovered_over_tag = null;

    public signal void link_event (LinkEvent event);

    public GemtextView (Core.Theme theme, Core.Uri current_uri) {
        Object (
            theme: theme,
            current_uri: current_uri,
            editable: false,
            cursor_visible: false,
            wrap_mode: Gtk.WrapMode.WORD_CHAR,
            has_tooltip: true
        );
    }

    construct {
        setup_theme ();
        create_static_tags ();
        connect_to_events ();
    }

    public void clear () {
        buffer.text = "";
        last_alt_text = null;
        last_inserted_ref = new GemtextRef ();
        hovered_over_tag = null;
        set_cursor_to ("text");
        var tags_to_remove = new Gee.ArrayList<unowned Gtk.TextTag> ();
        buffer.tag_table.foreach (tag => {
            if (tag is LinkTextTag || tag is PreformattedTextTag) {
                tags_to_remove.add (tag);
            }
        });

        foreach (var tag in tags_to_remove) {
            buffer.tag_table.remove (tag);
        }
    }

    public GemtextRef? display_line (Core.Line line) {
        Gtk.TextIter end;
        buffer.get_end_iter (out end);
        var text = displayable_text_for (line);
        var tag = tag_for (line);
        buffer.insert_with_tags (ref end, text, -1, tag);
        var line_ref = gemtext_ref_for (line);
        if (line_ref != last_inserted_ref) {
            last_inserted_ref = line_ref;
            buffer.create_mark (line_ref.to_string (), end, true);
            return line_ref;
        }

        return null;
    }

    public void scroll_to (GemtextRef line_ref) {
        var mark = buffer.get_mark (line_ref.to_string ());
        if (mark == null) {
            return;
        }

        scroll_to_mark  (mark, 0.1, true, 0.1, 0.1);
    }

    private string displayable_text_for (Core.Line line) {
        var text = line.get_display_content ();
        if (line.line_type == Core.LineType.LIST_ITEM) {
            text = "• " + text;
        } else if (line.line_type == Core.LineType.LINK) {
            try {
                var uri = Core.Uri.parse (line.get_url (), current_uri);
                if (uri.scheme != "gemini" && uri.scheme != "file") {
                    text = text + " 🌐️";
                }
            } catch (Core.UriError e) {
                warning ("Failed to parse url %s, error: %s".printf (line.get_url (), e.message));
                text = text + " ⚠️";
            }
        }

        return text + "\n";
    }

    private Gtk.TextTag? tag_for (Core.Line line) {
        switch (line.line_type) {
            case Core.LineType.HEADING_1:
                return h1_tag;
            case Core.LineType.HEADING_2:
                return h2_tag;
            case Core.LineType.HEADING_3:
                return h3_tag;
            case Core.LineType.QUOTE:
                return quote_tag;
            case Core.LineType.LIST_ITEM:
                return list_item_tag;
            case Core.LineType.LINK:
                try {
                    var uri = Core.Uri.parse (line.get_url (), current_uri);
                    var tag = new LinkTextTag (
                        theme,
                        uri,
                        line.get_url_desc ()
                    );

                    buffer.tag_table.add (tag);
                    return tag;
                } catch (Core.UriError e) {
                    warning ("Failed to parse uri %s, error: %s".printf (line.get_url (), e.message));
                    return text_tag;
                }
            case Core.LineType.PREFORMATTED_START:
                last_alt_text = line.get_alt_text ();
                var tag = new PreformattedTextTag (theme, last_alt_text);
                buffer.tag_table.add (tag);
                return tag;
            case Core.LineType.PREFORMATTED:
                var tag = new PreformattedTextTag (theme, last_alt_text);
                buffer.tag_table.add (tag);
                return tag;
            case Core.LineType.PREFORMATTED_END:
                var tag = new PreformattedTextTag (theme, last_alt_text);
                last_alt_text = null;
                buffer.tag_table.add (tag);
                return tag;
            case Core.LineType.TEXT:
            default:
                return text_tag;
        }
    }

    private GemtextRef gemtext_ref_for (Core.Line line) {
        switch (line.line_type) {
            case Core.LineType.HEADING_1:
                return last_inserted_ref.next_h1 ();
            case Core.LineType.HEADING_2:
                return last_inserted_ref.next_h2 ();
            case Core.LineType.HEADING_3:
                return last_inserted_ref.next_h3 ();
            default:
                return last_inserted_ref;
        }
    }

    private void setup_theme () {
        var style_ctx = get_style_context ();
        var previous_provider = theme.get_gemtext_css();
        style_ctx.add_provider (
            previous_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        theme.changed.connect (() => {
            quote_tag.paragraph_background_rgba = theme.block_background_color;
            buffer.tag_table.foreach (tag => {
                if (tag is LinkTextTag) {
                    ((LinkTextTag) tag).foreground_rgba = theme.link_color;
                } else if (tag is PreformattedTextTag) {
                    ((PreformattedTextTag) tag).paragraph_background_rgba = theme.block_background_color;
                }
            });

            var next_provider = theme.get_gemtext_css();
            style_ctx.add_provider (
                next_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

            style_ctx.remove_provider (previous_provider);
            previous_provider = next_provider;
        });
    }

    private void create_static_tags () {
        h1_tag = buffer.create_tag (
            "H1",
            scale: Pango.Scale.XX_LARGE,
            variant: Pango.Variant.SMALL_CAPS
        );

        h2_tag = buffer.create_tag (
            "H2",
            scale: Pango.Scale.X_LARGE,
            variant: Pango.Variant.SMALL_CAPS
        );

        h3_tag = buffer.create_tag (
            "H3",
            scale: Pango.Scale.LARGE,
            variant: Pango.Variant.SMALL_CAPS
        );

        quote_tag = buffer.create_tag (
            "QUOTE",
            style: Pango.Style.ITALIC,
            indent: 8,
            left_margin: 36,
            pixels_above_lines: 16,
            pixels_below_lines: 16,
            paragraph_background_rgba: theme.block_background_color
        );

        text_tag = buffer.create_tag (
            "TEXT",
            indent: 8
        );

        list_item_tag = buffer.create_tag (
            "LIST",
            left_margin: 36
        );
    }

    private void connect_to_events () {
        query_tooltip.connect (on_query_tooltip);
        motion_notify_event.connect ((view, event) => on_motion_notify (event));
        button_release_event.connect ((view, event) => on_button_release (event));
        populate_popup.connect ((view, menu) => on_populate_popup (menu));
    }

    private bool on_query_tooltip (int x, int y, bool keyboard_tooltip, Gtk.Tooltip tooltip) {
        var tag = tag_for_event (x, y);
        if (tag != null && tag is PreformattedTextTag) {
            var pref_tag = (PreformattedTextTag) tag;
            string tooltip_text = pref_tag.alt_text;
            if (tooltip_text == null || tooltip_text == "") {
                tooltip_text = _("Preformatted text without description.");
            }

            tooltip.set_text (tooltip_text);
            return true;
        }

        return false;
    }

    private bool on_motion_notify (Gdk.EventMotion event) {
        var tag = tag_for_event ((int) event.x, (int) event.y);
        if (tag != hovered_over_tag) {
            handle_hover_change (tag);
        }

        hovered_over_tag = tag;
        return false;
    }

    private Gtk.TextTag? tag_for_event (int event_x, int event_y) {
        int buffer_x;
        int buffer_y;
        window_to_buffer_coords (
            Gtk.TextWindowType.TEXT,
            event_x,
            event_y,
            out buffer_x,
            out buffer_y
        );

        Gtk.TextIter iter;
        get_iter_at_location (out iter, buffer_x, buffer_y);
        var all_tags = iter.get_tags ();
        if (all_tags == null || all_tags.length () == 0) {
            return null;
        } else {
            return all_tags.last ().data;
        }
    }

    private void handle_hover_change (Gtk.TextTag? new_tag) {
        var old_link_tag = link_tag_or_null (hovered_over_tag);
        var new_link_tag = link_tag_or_null (new_tag);
        var should_exit = old_link_tag != null && old_link_tag != new_link_tag;
        if (should_exit) {
            link_event (new LinkEvent (
                old_link_tag.uri.to_string (),
                old_link_tag.desc,
                LinkEventType.HOVER_EXIT
            ));
            set_cursor_to ("text");
            de_highlight (old_link_tag);
        }

        if (new_link_tag != null) {
            link_event (new LinkEvent (
                new_link_tag.uri.to_string (),
                new_link_tag.desc,
                LinkEventType.HOVER_ENTER
            ));
            set_cursor_to ("pointer");
            highlight (new_link_tag);
        }
    }

    private void set_cursor_to (string cursor_name) {
        var gdk_window = get_window (Gtk.TextWindowType.TEXT);
        if (gdk_window != null) {
            gdk_window.set_cursor (new Gdk.Cursor.from_name (
                gdk_window.get_display (),
                cursor_name
            ));
        }
    }

    private void de_highlight (LinkTextTag link_tag) {
        var transparent = Gdk.RGBA ();
        transparent.parse ("rgba(0, 0, 0, 0)");
        link_tag.paragraph_background_rgba = transparent;
    }

    private void highlight (LinkTextTag link_tag) {
        var background_color = theme.link_color.copy ();
        background_color.alpha = 0.07;
        link_tag.paragraph_background_rgba = background_color;
    }

    private bool on_button_release (Gdk.EventButton event) {
        var link_tag = link_tag_or_null (hovered_over_tag);
        if (link_tag == null) {
            return false;
        }

        LinkEventType? link_event_type = link_event_type_for (event);
        if (link_event_type == null) {
            return false;
        }

        link_event (new LinkEvent (
            link_tag.uri.to_string (),
            link_tag.desc,
            link_event_type
        ));

        return true;
    }

    private LinkEventType? link_event_type_for (Gdk.EventButton event) {
        switch (event.button) {
            case 1:
                return LinkEventType.LEFT_MOUSE_CLICK;
            case 2:
                return LinkEventType.MIDDLE_MOUSE_CLICK;
            case 3:
                return LinkEventType.RIGHT_MOUSE_CLICK;
            default:
                return null;
        }
    }

    private void on_populate_popup (Gtk.Menu popup_menu) {
        var link_tag = link_tag_or_null (hovered_over_tag);
        if (link_tag == null) {
            return;
        }

        var uri = link_tag.uri;
        var uri_str = uri.to_string ();
        var desc = link_tag.desc;
        popup_menu.foreach (popup_menu.remove);

        var open_item = new Gtk.MenuItem.with_label (_("Open link"));
        open_item.show ();
        popup_menu.append (open_item);
        open_item.activate.connect (() => {
            link_event (new LinkEvent (
                uri_str,
                desc,
                LinkEventType.LEFT_MOUSE_CLICK
            ));
        });

        if (uri.scheme == "gemini" || uri.scheme == "file") {
            var open_in_new_tab_item = new Gtk.MenuItem.with_label (_("Open link in a new tab"));
            open_in_new_tab_item.show ();
            popup_menu.append (open_in_new_tab_item);
            open_in_new_tab_item.activate.connect (() => {
                link_event (new LinkEvent (
                    uri_str,
                    desc,
                    LinkEventType.MIDDLE_MOUSE_CLICK
                ));
            });
        }

        var separator_item = new Gtk.SeparatorMenuItem ();
        separator_item.show ();
        popup_menu.append (separator_item);

        var clipboard = Gtk.Clipboard.get_default (Gdk.Display.get_default ());

        var copy_uri_item = new Gtk.MenuItem.with_label (_("Copy link"));
        copy_uri_item.show ();
        popup_menu.append (copy_uri_item);
        copy_uri_item.activate.connect (() => {
            clipboard.set_text (uri_str, -1);
        });

        var copy_desc_item = new Gtk.MenuItem.with_label (_("Copy description"));
        copy_desc_item.show ();
        popup_menu.append (copy_desc_item);
        copy_desc_item.activate.connect (() => {
            clipboard.set_text (desc, -1);
        });
    }

    private LinkTextTag? link_tag_or_null (Gtk.TextTag? any_tag) {
        return (any_tag != null && any_tag is LinkTextTag) ? (LinkTextTag) any_tag : null;
    }
}

private class Starfish.UI.LinkTextTag : Gtk.TextTag {

    public Core.Uri uri { get; construct; }
    public string desc { get; construct; }

    public LinkTextTag (Core.Theme theme, Core.Uri uri, string desc) {
        Object (
            uri: uri,
            desc: desc,
            underline: Pango.Underline.LOW,
            pixels_below_lines: 4,
            foreground_rgba: theme.link_color,
            foreground_set: true
        );
    }
}

private class Starfish.UI.PreformattedTextTag : Gtk.TextTag {

    public string? alt_text { get; construct; }

    public PreformattedTextTag (Core.Theme theme, string? alt_text) {
        Object (
            alt_text: alt_text,
            family: "Monospace",
            wrap_mode: Gtk.WrapMode.NONE,
            paragraph_background_rgba: theme.block_background_color,
            paragraph_background_set: true
        );
    }
}

