public interface Starfish.Core.Storage : Object {

    public abstract string load_homepage ();
    public abstract void save_homepage (string homepage);
    public abstract Variant load_sessions ();
    public abstract void save_sessions (Variant session);
    public abstract int load_focused_tab ();
    public abstract void save_focused_tab (int focused_tab);
    public abstract string[] load_tabs ();
    public abstract void save_tabs (string[] tabs);

}
