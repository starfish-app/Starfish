public class Starfish.Core.Tab : Object {

    public string id { get; construct; }
    public Session session { get; construct; }

    public Core.Uri uri {
        get { return session.current_uri; }
    }

    public Tab (string id, Session session) {
        Object (
            id: id,
            session: session
        );
    }
}

