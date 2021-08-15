public class Starfish.Templates.NotFound : Template {

        public static string URI_KEY = "uri";
        public static string META_KEY = "meta";

    private const string template = _("""# Not found

```
    Λ
___/ \___
‛𑑍     _   ⸲’     Not found 👽️
 /,” ‛⹁\
/’    ‛\
```

The page ${uri} wasn't found. It doesn't exist yet, but may be created in the future. For now you can:

* Go back to the last visited page.
* Check if page URL is spelled correctly.
* Try visiting this page again later.

Technical details:

```

Gemini response details

<STATUS>: 51

<META>: ${meta}

```
""");

    protected override string get_template () {
        return template;
    }
}

