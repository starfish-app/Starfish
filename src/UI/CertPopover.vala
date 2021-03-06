public class Starfish.UI.CertPopover : Gtk.Popover {


    public Window? window { get; set; default = null; }

    private Core.Session? session;
    private Core.CertInfo? cert_info;
    private Core.CertInfo? client_cert_info;
    private Core.ClientCertRepo? cert_repo;

    private Gtk.Grid grid;
    private Granite.MessageDialog? full_details = null;

    public CertPopover (Gtk.Widget relative_to) {
        Object (relative_to: relative_to);
    }

    construct {
        grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            margin = 16,
            baseline_row = 0,
            column_homogeneous = false,
            column_spacing = 16,
            row_homogeneous  = false,
            row_spacing  = 8
        };

        add (grid);
        show.connect (() => update_content ());
    }

    public void set_session (Core.Session session) {
        this.session = session;
        cert_info = session.cert_info;
        client_cert_info = session.client_cert_info;
        cert_repo = session.client_cert_repo;
    }

    private void update_content () {
        foreach (var child in grid.get_children ()) {
            grid.remove (child);
        }

        var heading = set_up_heading ();
        grid.attach (heading, 0, 0, 2, 1);
        if (cert_info != null) {
            update_cert_info ();
        }

        show_all ();
    }

    private void update_cert_info () {
        var uri = session.current_uri;
        var server_heading = new Gtk.Label (_("Server identity")) {
            halign = Gtk.Align.START
        };

        server_heading.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
        grid.attach (server_heading, 0, 1, 2, 1);
        Gtk.Widget last_attached = server_heading;
        last_attached = attach_row (grid, last_attached, _("Name"), cert_info.common_name, cert_info.is_not_applicable_to_uri(), _("Server certificate is not applicable to the domain you are requesting."));
        last_attached = attach_row (grid, last_attached, _("Country"), cert_info.country_name);
        last_attached = attach_row (grid, last_attached, _("Orgamization"), cert_info.organization_name);
        last_attached = attach_row (grid, last_attached, _("Active from"), local_date_time (cert_info.active_from), cert_info.is_inactive (), _("Server certificate's activation date has not yet arrived."));
        last_attached = attach_row (grid, last_attached, _("Expires at"), local_date_time (cert_info.expires_at), cert_info.is_expired (), _("Server certificate's expiration date has passed."));
        last_attached = attach_row (grid, last_attached, _("Fingerprint"), cert_info.fingerprint);

        var server_details_button = new Gtk.Button.with_label (_("Show Details"));
        server_details_button.clicked.connect (() => {
            show_full_details (cert_info, "server");
            popdown ();
        });

        grid.attach_next_to (
            server_details_button,
            last_attached,
            Gtk.PositionType.BOTTOM,
            2,
            1
        );

        last_attached = server_details_button;

        var repo = session.client_cert_repo;
        var certs_linekd_to_host = repo.existing_certificate_names (uri.host);
        var has_certs_for_host = !certs_linekd_to_host.is_empty;
        if (client_cert_info == null && has_certs_for_host) {
            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            grid.attach_next_to (separator, last_attached, Gtk.PositionType.BOTTOM, 2, 1);
            last_attached = separator;
            var client_hading = new Gtk.Label (_("Client identity")) {
                halign = Gtk.Align.START
            };

            client_hading.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            grid.attach_next_to (client_hading, last_attached, Gtk.PositionType.BOTTOM, 2, 1);
            last_attached = client_hading;

            var missing_client_identity_label = new Gtk.Label (
                _("You have identities associated with other pages on the %s domain.").printf (uri.host)
            ) {
                halign = Gtk.Align.START
            };

            grid.attach_next_to (
                missing_client_identity_label,
                last_attached,
                Gtk.PositionType.BOTTOM,
                2,
                1
            );

            last_attached = missing_client_identity_label;
            var use_identity_button = new Gtk.Button.with_label (_("Use Identity"));
            use_identity_button.clicked.connect (() => {
                show_client_cert_picker_for (uri);
                popdown ();
            });

            grid.attach_next_to (
                use_identity_button,
                last_attached,
                Gtk.PositionType.BOTTOM,
                1,
                1
            );

            last_attached = use_identity_button;
        }

        if (client_cert_info != null) {
            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            grid.attach_next_to (separator, last_attached, Gtk.PositionType.BOTTOM, 2, 1);
            last_attached = separator;
            var client_hading = new Gtk.Label (_("Client identity")) {
                halign = Gtk.Align.START
            };

            client_hading.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            grid.attach_next_to (client_hading, last_attached, Gtk.PositionType.BOTTOM, 2, 1);
            last_attached = client_hading;

            last_attached = attach_row (grid, last_attached, _("Name"), client_cert_info.common_name);
            var client_unlink_button = new Gtk.Button.with_label (_("Stop Using Identity"));
            client_unlink_button.clicked.connect (() => {
                cert_repo.unlink (uri, client_cert_info.common_name);
                popdown ();
                session.navigate_to (uri.to_string ());
            });

            grid.attach_next_to (
                client_unlink_button,
                last_attached,
                Gtk.PositionType.BOTTOM,
                1,
                1
            );

            last_attached = client_unlink_button;

            var client_details_button = new Gtk.Button.with_label (_("Show Details"));
            client_details_button.clicked.connect (() => {
                show_full_details (client_cert_info, "client");
                popdown ();
            });

            grid.attach_next_to (
                client_details_button,
                last_attached,
                Gtk.PositionType.RIGHT,
                1,
                1
            );

            last_attached = client_details_button;
        }
    }

    private Gtk.Widget set_up_heading () {
        var heading = new Gtk.Label (null) {
            halign = Gtk.Align.START
        };

        unowned var style = heading.get_style_context ();
        style.add_class (Granite.STYLE_CLASS_H3_LABEL);
        if (cert_info == null) {
            heading.label = _("Your connection is insecure");
            style.add_class ("error");
        } else if (cert_info.is_not_applicable_to_uri ()) {
            heading.label = _("Your connection to %s is insecure").printf (cert_info.host);
            style.add_class ("error");
        } else if (cert_info.is_inactive () || cert_info.is_expired ()) {
            heading.label = _("Your connection to %s might be insecure").printf (cert_info.host);
            style.add_class ("warning");
        } else {
            heading.label = _("Your connection to %s is secure").printf (cert_info.host);
            style.add_class ("success");
        }

        return heading;
    }

    private Gtk.Widget attach_row (
        Gtk.Grid grid,
        Gtk.Widget sibling,
        string name,
        string? data = null,
        bool is_error = false,
        string? error_msg = null
    ) {
        if (data == null) {
            return sibling;
        }

        var name_lbl = new Gtk.Label (name) {
            halign = Gtk.Align.START
        };

        grid.attach_next_to (name_lbl, sibling, Gtk.PositionType.BOTTOM, 1, 1);
        var data_lbl = new Gtk.Label (data) {
            halign = Gtk.Align.START,
            selectable = true
        };

        grid.attach_next_to (data_lbl, name_lbl, Gtk.PositionType.RIGHT, 1, 1);
        if (is_error) {
            unowned var style = data_lbl.get_style_context ();
            style.add_class ("error");
            var icon = new Gtk.Image () {
                gicon = new ThemedIcon ("dialog-error-symbolic"),
                pixel_size = 16,
                tooltip_text = error_msg
            };

            grid.attach_next_to (icon, data_lbl, Gtk.PositionType.RIGHT, 1, 1);
        }

        return name_lbl;
    }

    private void show_full_details (Core.CertInfo cert_info, string source) {
        if (full_details == null) {
            full_details = new Granite.MessageDialog.with_image_from_icon_name (
                _("Certificate details"),
                _("Full details on the currently used %s certificate.").printf (source),
                "text-x-generic",
                Gtk.ButtonsType.CLOSE
            ) {
                badge_icon = new ThemedIcon ("dialog-information")
            };

            var cert_txt = new Gtk.TextBuffer (null) {
                text = cert_info.full_print
            };

            var cert_view = new Gtk.TextView.with_buffer (cert_txt) {
                editable = false
            };

            cert_view.get_style_context ().add_class (Granite.STYLE_CLASS_TERMINAL);
            var scrollable_cert_view = new Gtk.ScrolledWindow (null, null){
                width_request = 720,
                height_request = 360
            };

            scrollable_cert_view.add (cert_view);
            full_details.custom_bin.add (scrollable_cert_view);
            full_details.show_all ();
            full_details.response.connect (() => {
                full_details.destroy ();
                full_details = null;
            });

        }

        full_details.show ();
    }

    private string local_date_time (DateTime dt) {
        var time_fmt = Granite.DateTime.get_default_time_format ();
        var date_fmt = Granite.DateTime.get_default_date_format (false, true, true);
        return "%s %s".printf (dt.format (time_fmt), dt.format (date_fmt));
    }

    private void show_client_cert_picker_for (Core.Uri uri) {
        var dialog = new Granite.Dialog () {
            transient_for = window
        };

        var header = new Granite.HeaderLabel (_("Pick identity"));
        var layout = new Gtk.Grid () {
            row_spacing = 12,
            margin = 12
        };

        layout.attach (header, 0, 1);
        var certs_list = new ClientCertListBox (session.client_cert_repo, uri, true, false);
        certs_list.cert_picked.connect ((t, c) => {
            dialog.destroy ();
            window.activate_action (Window.ACTION_RELOAD, null);
        });

        layout.attach (certs_list, 0, 2);
        dialog.get_content_area ().add (layout);
        dialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        dialog.response.connect ((res_id) => dialog.destroy ());
        dialog.show_all ();
    }
}

