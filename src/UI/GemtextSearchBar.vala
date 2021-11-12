public class Starfish.UI.GemtextSearchBar : Gtk.SearchBar {

    public GemtextView gemtext_view { get; construct; }

    private Gtk.SearchEntry search_entry;
    private Gtk.TextIter? match_start = null;
    private Gtk.TextIter? match_end = null;

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

        var next = new Gtk.Button.from_icon_name ("go-down-symbolic") {
            tooltip_text = _("Find next occurrence")
        };

        next.clicked.connect (() => on_search (match_end));
        var prev = new Gtk.Button.from_icon_name ("go-up-symbolic") {
            tooltip_text = _("Find previous occurrence")
        };

        prev.clicked.connect (() => on_search (match_start, false));
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8) {
            halign = Gtk.Align.START
        };

        box.add (search_entry);
        box.add (next);
        box.add (prev);
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
    }

    private void on_search (Gtk.TextIter? start, bool forward = true) {
        var term = search_entry.text;
        var buffer = gemtext_view.buffer;

        if (term == null || term == "") {
            clear ();
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

        bool term_found = false;
        if (forward) {
            term_found = start_iter.forward_search (
                term,
                Gtk.TextSearchFlags.TEXT_ONLY,
                out match_start,
                out match_end,
                null
            );
        } else {
            term_found = start_iter.backward_search (
                term,
                Gtk.TextSearchFlags.TEXT_ONLY,
                out match_start,
                out match_end,
                null
            );
        }

        if (term_found) {
            buffer.select_range (match_start, match_end);
            gemtext_view.scroll_to_iter (match_start, 0.1, false, 0.0, 0.0);
        } else {
            clear ();
        }
    }
}

