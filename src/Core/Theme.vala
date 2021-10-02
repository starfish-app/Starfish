public class Starfish.Core.Theme : Object {

    public static double DEFAULT_FONT_SIZE = 1.2;
    public static Gdk.RGBA DEFAULT_BLOCK_BACKGROUND_COLOR = Gdk.RGBA ();
    public static Gdk.RGBA DEFAULT_DARK_SCHEME_LINK_COLOR = Gdk.RGBA ();
    public static Gdk.RGBA DEFAULT_LIGHT_SCHEME_LINK_COLOR = Gdk.RGBA ();

    static construct {
        DEFAULT_BLOCK_BACKGROUND_COLOR.parse ("rgba(130, 130, 130, 0.2)");
        DEFAULT_DARK_SCHEME_LINK_COLOR.parse ("rgba(135, 204, 239, 1)");
        DEFAULT_LIGHT_SCHEME_LINK_COLOR.parse ("rgba(0, 80, 120, 1)");
    }

    public double base_font_size { get; set; }
    public Gdk.RGBA block_background_color { get; set; }
    public Gdk.RGBA link_color { get; set; }

    public Theme.os (Settings gsettings) {
        gsettings.bind ("font-size", this, "base_font_size", SettingsBindFlags.GET);

        block_background_color = DEFAULT_BLOCK_BACKGROUND_COLOR;

        var granite_settings = Granite.Settings.get_default ();
        link_color = pick_link_color (granite_settings.prefers_color_scheme);
        granite_settings.notify["prefers-color-scheme"].connect (() => {
            link_color = pick_link_color (granite_settings.prefers_color_scheme);
        });
    }

    private Gdk.RGBA pick_link_color (Granite.Settings.ColorScheme scheme) {
        if (scheme == Granite.Settings.ColorScheme.DARK) {
            return DEFAULT_DARK_SCHEME_LINK_COLOR;
        } else {
            return DEFAULT_LIGHT_SCHEME_LINK_COLOR;
        }
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

