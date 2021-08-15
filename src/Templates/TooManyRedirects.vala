public class Starfish.Templates.TooManyRedirects : Template {

        public static string URI_KEY = "uri";
        public static string REDIRECT_URI_KEY = "redirect-uri";

    private const string template = _("""# Too many redirects

```
    Λ
___/ \___
‛𑑍     _   ⸲’     Too many redirects 🏓️
 /,” ‛⹁\
/’    ‛\
```

The page at ${uri} is attempting to redirect you through many hoops. Redirect will not be followed automatically to prevent loops. If you want you can open it yourself:

=> ${redirect-uri}

Or you can go back to the last visited page.

""");

    protected override string get_template () {
        return template;
    }
}

