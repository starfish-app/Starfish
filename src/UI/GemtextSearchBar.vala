public class Starfish.UI.GemtextSearchBar : Gtk.SearchBar {

    public GemtextView gemtext_view { get; construct; }

    private Gtk.SearchEntry search_entry;
    private Gtk.TextIter? match_start = null;
    private Gtk.TextIter? match_end = null;
    private Gtk.Button next_button;
    private Gtk.Button prev_button;
    private Gtk.ToggleButton caps_toggle;

    public GemtextSearchBar (GemtextView gemtext_view) {
        Object (
            gemtext_view: gemtext_view,
            show_close_button: true
        );
    }

    construct {
        search_entry = new Gtk.SearchEntry () {
            can_focus = false
        };

        search_entry.realize.connect (() => {
            search_entry.can_focus = true;
            search_entry.grab_focus ();
        });

        search_entry.search_changed.connect (() => on_search (match_start));
        search_entry.activate.connect (() => on_search (match_end));
        search_entry.next_match.connect (() => on_search (match_end));
        search_entry.previous_match.connect (() => on_search (match_end, false));
        search_entry.stop_search.connect (clear);

        next_button = new Gtk.Button.from_icon_name ("go-down-symbolic") {
            tooltip_text = _("Find next occurrence"),
            sensitive = false
        };

        next_button.clicked.connect (() => on_search (match_end));

        prev_button = new Gtk.Button.from_icon_name ("go-up-symbolic") {
            tooltip_text = _("Find previous occurrence"),
            sensitive = false
        };

        prev_button.clicked.connect (() => on_search (match_start, false));

        caps_toggle = new Gtk.ToggleButton() {
            image = new Gtk.Image.from_icon_name (
                "font-x-generic-symbolic",
                Gtk.IconSize.BUTTON
            ),
            focus_on_click = false,
            tooltip_text = _("Case insensitive"),
        };

        caps_toggle.notify["active"].connect ((o, p) => {
            on_search (match_start);
            caps_toggle.tooltip_text = caps_toggle.active ? _("Case sensitive") : _("Case insensitive");
        });

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8) {
            halign = Gtk.Align.START
        };

        box.add (search_entry);
        box.add (next_button);
        box.add (prev_button);
        box.add (caps_toggle);
        add (box);
        connect_entry (search_entry);
    }

    public void clear () {
        match_start = null;
        match_end = null;
        var buffer = gemtext_view.buffer;
        Gtk.TextIter iter;
        buffer.get_start_iter (out iter);
        buffer.select_range (iter, iter);
        next_button.sensitive = false;
        prev_button.sensitive = false;
        caps_toggle.active = false;
    }

    private void on_search (Gtk.TextIter? start, bool forward = true) {
        var term = search_entry.text;
        var buffer = gemtext_view.buffer;

        if (term == null || term == "") {
            clear ();
            search_entry.get_style_context ().remove_class (Gtk.STYLE_CLASS_ERROR);
            search_entry.primary_icon_name = "edit-find-symbolic";
            return;
        }

        Gtk.TextIter start_iter;
        if (start == null) {
            if (forward) {
                buffer.get_start_iter (out start_iter);
            } else {
                buffer.get_end_iter (out start_iter);
            }
        } else {
            start_iter = start;
        }

        Gtk.TextSearchFlags flags;
        if (caps_toggle.active) {
            flags = Gtk.TextSearchFlags.TEXT_ONLY ^ Gtk.TextSearchFlags.CASE_INSENSITIVE;
        } else {
            flags = Gtk.TextSearchFlags.TEXT_ONLY;
        }

        bool term_found = false;
        if (forward) {
            term_found = start_iter.forward_search (
                term,
                flags,
                out match_start,
                out match_end,
                null
            );

            if (!term_found) {
                // Loop search
                buffer.get_start_iter (out start_iter);
                term_found = start_iter.forward_search (
                    term,
                    flags,
                    out match_start,
                    out match_end,
                    null
                );
            }
        } else {
            term_found = start_iter.backward_search (
                term,
                flags,
                out match_start,
                out match_end,
                null
            );

            if (!term_found) {
                // Loop search
                buffer.get_end_iter (out start_iter);
                term_found = start_iter.backward_search (
                    term,
                    flags,
                    out match_start,
                    out match_end,
                    null
                );
            }
        }

        if (term_found) {
            buffer.select_range (match_start, match_end);
            gemtext_view.scroll_to_iter (match_start, 0.1, false, 0.0, 0.0);
            next_button.sensitive = true;
            prev_button.sensitive = true;
            search_entry.get_style_context ().remove_class (Gtk.STYLE_CLASS_ERROR);
            search_entry.primary_icon_name = "edit-find-symbolic";
        } else {
            clear ();
            if (search_entry.text != "") {
                search_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);
                search_entry.primary_icon_name = "dialog-error-symbolic";
            }
        }
    }
}

