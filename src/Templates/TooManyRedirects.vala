public class Starfish.Templates.TooManyRedirects : Template {

        public static string URI_KEY = "uri";
        public static string REDIRECT_URI_KEY = "redirect-uri";

    private const string template = _("""# Too many redirects

```
    Ξ
___/ \___
βπ     _   βΈ²β     Too many redirects ποΈ
 /,β ββΉ\
/β    β\
```

The page at ${uri} is attempting to redirect you through many hoops. Redirect will not be followed automatically to prevent loops. If you want you can open it yourself:

=> ${redirect-uri}

Or you can go back to the last visited page.

""");

    protected override string get_template () {
        return template;
    }
}

