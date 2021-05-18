public interface Starfish.Core.SessionStorage : Object {

    public abstract Variant load ();
    public abstract void save (Variant session);

}
