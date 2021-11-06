public class Starfish.UI.ContentStack : Gtk.Stack {

    public string default_view { get; construct; }
    public Gee.Map<string, ResponseView> response_views { get; construct; }

    public ContentStack.with_views (string key, ResponseView view, ...) {
        var views = new Gee.HashMap<string, ResponseView> ();
        views[key] = view;
        var l = va_list();
        while (true) {
            string? next_key = l.arg ();
            if (next_key == null) {
                break;
            }

            ResponseView next_view = l.arg ();
            views[next_key] = next_view;
        }
        this (views, key);
    }

    public ContentStack (Gee.Map<string, ResponseView> response_views, string default_view) {
        Object (response_views: response_views, default_view: default_view);
    }

    construct {
        foreach (var entry in response_views) {
            add_named (entry.value, entry.key);
        }
        set_visible_child_name (default_view);
    }

    public void clear () {
        foreach (var entry in response_views) {
            entry.value.clear ();
        }
        set_visible_child_name (default_view);
    }

    public void display (Core.Response response) {
        Gee.Map.Entry<string, ResponseView>? pick = null;
        foreach (var entry in response_views) {
            entry.value.clear ();
            if (entry.value.can_display (response) && pick == null) {
                pick = entry;
            }
        }

        if (pick != null) {
            set_visible_child_name (pick.key);
            reset_scroll ();
            pick.value.display (response);
        }
    }

    private void reset_scroll () {
        if (visible_child is Gtk.ScrolledWindow) {
            var sw = ((Gtk.ScrolledWindow) visible_child);
            sw.hadjustment.value = sw.hadjustment.lower;
            sw.vadjustment.value = sw.vadjustment.lower;
        }
    }
}
