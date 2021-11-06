public class Starfish.UI.GemtextRef : Object {

    public int h1 { get; construct; } // 0 stands for null
    public int h2 { get; construct; } // 0 stands for null
    public int h3 { get; construct; } // 0 stands for null

    public GemtextRef (int h1 = 0, int h2 = 0, int h3 = 0) {
        Object (h1: h1, h2: h2, h3: h3);
    }

    public GemtextRef next_h1 () {
        return new GemtextRef (h1 + 1);
    }

    public GemtextRef next_h2 () {
        return new GemtextRef (h1, h2 + 1);
    }

    public GemtextRef next_h3 () {
        return new GemtextRef (h1, h2, h3 + 1);
    }

    public string to_string () {
        return "%d:%d:%d".printf (h1, h2, h3);
    }
}

