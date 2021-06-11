public class Starfish.UI.PreferencesDialog : Granite.Dialog {

    public Settings settings { private get; construct; }

    public PreferencesDialog (Settings settings) {
        Object (
            settings: settings,
            deletable: false,
            resizable: false,
            title: _("Preferences")
        );
    }

    construct {
        var grid = new Gtk.Grid () {
            margin = 12,
            column_spacing = 12,
            row_spacing = 6
        };

        grid.attach (new Granite.HeaderLabel (_("Home")), 0, 0, 3);
        grid.attach (new Gtk.Label (_("Homepage URL")) {
            label = _("Homepage URL"),
            halign = Gtk.Align.END,
            margin_start = 12
        }, 0, 1);

        var homepage_entry = new Gtk.Entry () {
            input_purpose = Gtk.InputPurpose.URL,
            width_request = 360
        };

        var homepage_validation_msg = new Gtk.Label (null) {
            halign = Gtk.Align.END
        };

        homepage_validation_msg.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);

        homepage_entry.text = settings.get_string ("homepage");
        homepage_entry.changed.connect (() => {
            var raw_uri = homepage_entry.text;
            try {
                var uri = Core.Uri.parse (raw_uri);
                if (uri.scheme != "gemini") {
                    homepage_entry.secondary_icon_name = "dialog-error-symbolic";
                    homepage_validation_msg.label = _("Please provide a link to a gemini site.");
                    return;
                }

                if (uri.host == null || uri.host == "") {
                    homepage_entry.secondary_icon_name = "dialog-error-symbolic";
                    homepage_validation_msg.label = _("Please define a domain.");
                    return;
                }

                if (uri.resolve_host ().length == 0) {
                    homepage_entry.secondary_icon_name = "dialog-error-symbolic";
                    homepage_validation_msg.label = _("Could not resolve domain %s.".printf (uri.host));
                    return;
                }

            } catch (Core.UriError e) {
                homepage_entry.secondary_icon_name = "dialog-error-symbolic";
                homepage_validation_msg.label = _("Could not parse the link. Error: %s".printf (e.message));
                return;
            };

            homepage_entry.secondary_icon_name = null;
            homepage_validation_msg.label = null;
            settings.set_string ("homepage", raw_uri);
        });

        grid.attach (homepage_entry, 1, 1, 2);
        grid.attach (homepage_validation_msg, 1, 2, 2);
        get_content_area ().add (grid);

        var close_button = (Gtk.Button) add_button (_("Close"), Gtk.ResponseType.CLOSE);
        close_button.clicked.connect (() => {
            destroy ();
        });
    }
}
