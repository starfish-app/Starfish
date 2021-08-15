public class Starfish.Templates.SlowDown : Template {

        public static string URI_KEY = "uri";
        public static string SECONDS_TO_WAIT_KEY = "seconds-to-wait";

    private const string template = _("""# Too many requests

```
    Λ
___/ \___
‛𑑍     _   ⸲’     Slow down 🐢️
 /,” ‛⹁\
/’    ‛\
```

The page at ${uri} under too much load right now, it requested you wait a little before making another request to it. To proceed you can:

* Go back to the last visited page.
* Try reloading this page again in ${seconds-to-wait} seconds.

Technical details:

```

Gemini response details

<STATUS>: 44

<META>: ${seconds-to-wait}

```
""");

    protected override string get_template () {
        return template;
    }
}

