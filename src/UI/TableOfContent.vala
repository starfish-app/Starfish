public class Starfish.UI.TableOfContent : Gtk.MenuButton {

    private OnRefClick ref_click_delegate;
    private Gtk.Grid line_links;

    public TableOfContent (owned OnRefClick ref_click_delegate) {
        Object (
            image: new Gtk.Image.from_icon_name (
                "format-justify-right",
                Gtk.IconSize.LARGE_TOOLBAR
            ),
            tooltip_text: _("Table of contents"),
            direction: Gtk.ArrowType.NONE,
            relief: Gtk.ReliefStyle.NONE,
            can_focus: false,
            margin_end: 8,
            halign: Gtk.Align.END,
            valign: Gtk.Align.START
        );

        this.ref_click_delegate = (owned) ref_click_delegate;
    }

    construct {
        line_links = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            row_spacing = 8,
            margin = 8
        };

        var scrollable = new Gtk.ScrolledWindow (null, null) {
            propagate_natural_height = true,
            propagate_natural_width = true,
            max_content_height = 240
        };

        scrollable.add (line_links);
        scrollable.show_all ();
        popover = new Gtk.Popover (this);
        popover.add (scrollable);
    }

    public void clear () {
        sensitive = false;
        popover.popdown ();
        foreach (var link in line_links.get_children ()) {
            line_links.remove (link);
        }
    }

    public void add_ref (GemtextRef line_ref, Core.Line line) {
        var txt = line.get_display_content ();
        var indent = ((line_ref.h2 > 0) ? 8 : 0) + ((line_ref.h3 > 0) ? 8 : 0);
        var button = new Gtk.LinkButton.with_label ("", txt) {
            margin_start = indent,
            halign = Gtk.Align.START,
            can_focus = false,
            has_tooltip = false
        };

        button.activate_link.connect (() => {
            ref_click_delegate (line_ref);
            popover.popdown ();
            return true;
        });

        line_links.add (button);
        line_links.show_all ();
        sensitive = true;
    }
}

public delegate void Starfish.UI.OnRefClick (GemtextRef line_ref);

