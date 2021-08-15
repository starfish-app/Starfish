public class Starfish.Templates.Gone : Template {

        public static string URI_KEY = "uri";
        public static string META_KEY = "meta";

    private const string template = _("""# Gone

```
    Λ
___/ \___
‛𑑍     _   ⸲’     Gone 🗑️
 /,” ‛⹁\
/’    ‛\
```

The page ${uri} used to exist but has since been repoved. It will never be available again. To proceed you can go back to the last visited page.

Technical details:

```

Gemini response details

<STATUS>: 52

<META>: ${meta}

```
""");

    protected override string get_template () {
        return template;
    }
}

