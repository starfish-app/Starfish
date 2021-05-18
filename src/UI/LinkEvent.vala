public class Starfish.UI.LinkEvent : Object {

    public string link_url { get; construct; }
    public string link_description { get; construct; }
    public LinkEventType event_type { get; construct; }

    public LinkEvent (
        string link_url,
        string link_description,
        LinkEventType event_type
    ) {
        Object (
            link_url: link_url,
            link_description: link_description,
            event_type: event_type
        );
    }
}

