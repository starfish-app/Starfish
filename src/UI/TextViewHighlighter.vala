public class Starfish.UI.TextViewHighlighter : Gtk.Box {

    public bool error { get; set; default = false; }

    private static Gtk.CssProvider style_provider;
    private static Granite.Settings settings;

    static construct {
        style_provider = new Gtk.CssProvider ();
        style_provider.load_from_resource ("hr/from/josipantolis/starfish/TextViewHighlighter.css");
        settings = Granite.Settings.get_default ();
    }

    public TextViewHighlighter (Gtk.Widget child) {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 1,
            child: child,
            hexpand: true,
            vexpand: false
        );
        set_up_focus_tracking ();
        set_up_light_mode_tracking ();
        set_up_error_tracking ();
        set_style_provider ();
    }

    private void set_up_light_mode_tracking () {
        update_light_class ();
        settings.notify["prefers-color-scheme"].connect (update_light_class);
    }

    private void update_light_class () {
        var scheme = settings.prefers_color_scheme;
        var is_light = scheme != Granite.Settings.ColorScheme.DARK;
        if (is_light) {
            get_style_context ().add_class ("light");
        } else {
            get_style_context ().remove_class ("light");
        }
    }

    private void set_up_focus_tracking () {
        var child = find_child ();
        child.focus_in_event.connect (() => {
            get_style_context ().add_class ("focus");
            return false;
        });

        child.focus_out_event.connect (() => {
            get_style_context ().remove_class ("focus");
            return false;
        });
    }

    private void set_up_error_tracking () {
        notify["error"].connect (() => {
            if (error) {
                get_style_context ().add_class ("error");
            } else {
                get_style_context ().remove_class ("error");
            }
        });
    }

    private void set_style_provider () {
        get_style_context ().add_class ("highlighter");
        get_style_context ().add_provider (
            style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        find_child ().get_style_context ().add_provider (
            style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    private Gtk.Widget find_child () {
        Gtk.Widget view = this;
        while (view != null && view is Gtk.Container) {
            var children = ((Gtk.Container) view).get_children ();
            if (children == null || children.length() == 0) {
                return view;
            }

            view = children.nth_data (0);
        }

        return view;
    }
}

