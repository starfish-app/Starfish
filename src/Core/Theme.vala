public class Starfish.Core.Theme : Object {

    public static double DEFAULT_FONT_SIZE = 1.2;
    public static Gdk.RGBA DEFAULT_BLOCK_BACKGROUND_COLOR = Gdk.RGBA ();

    static construct {
        DEFAULT_BLOCK_BACKGROUND_COLOR.parse ("rgba(130, 130, 130, 0.2)");
    }

    public double base_font_size { get; set; }
    public Gdk.RGBA block_background_color { get; set; }
    private Gtk.StyleContext? _system_style = null;
    private Gdk.RGBA? _link_color = null;
    public Gdk.RGBA? link_color { get {
        if (_link_color == null) {
            setup_link_color ();
        }

        return _link_color;
    }}

    public signal void changed ();

    public Theme.os (Settings gsettings) {
        base_font_size = gsettings.get_double ("font-size");
        gsettings.changed.connect ((key) => {
            if (key != "font-size") {
                return;
            }

            base_font_size = gsettings.get_double (key);
            changed ();
        });
        block_background_color = DEFAULT_BLOCK_BACKGROUND_COLOR;
    }

    private void setup_link_color () {
        if (_system_style == null) {
            setup_system_style ();
        }

        _link_color = (Gdk.RGBA) _system_style.get_property (
            Gtk.STYLE_PROPERTY_COLOR,
            Gtk.StateFlags.LINK
        );
    }

    private void setup_system_style () {
        var widget_path = new Gtk.WidgetPath ();
        widget_path.append_type (typeof (Gtk.LinkButton));
        widget_path.iter_set_object_name (-1, "selection");

        _system_style = new Gtk.StyleContext ();
        _system_style.set_path (widget_path);
        _system_style.changed.connect (() => {
            var new_color = (Gdk.RGBA) _system_style.get_property (
                Gtk.STYLE_PROPERTY_COLOR,
                Gtk.StateFlags.LINK
            );

            if (new_color != _link_color) {
                _link_color = new_color;
                changed ();
            }
        });
    }

    public Gtk.CssProvider get_gemtext_css () {
        var style = """
            textview {
                font-size: %.1fem;
            }

            grid {
                font-size: %.1fem;
            }
        """.printf (base_font_size, base_font_size);

        var provider = new Gtk.CssProvider ();
        try {
            provider.load_from_data (style, style.length);
        } catch (Error e) {
            warning ("Failed to load custom gemtext CSS, will use default style. Error: %s", e.message);
        }

        return provider;
    }
}

