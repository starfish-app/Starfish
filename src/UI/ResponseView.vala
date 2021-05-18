public interface Starfish.UI.ResponseView : Gtk.Widget {

    public abstract bool can_display (Core.Response response);
    public abstract void clear ();
    public abstract void display (Core.Response response);

}
