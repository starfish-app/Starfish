public class Starfish.Templates.ConnectionFailed : Template {

        public static string URI_KEY = "uri";
        public static string DOMAIN_KEY = "domain";
        public static string ERROR_MESSAGE_KEY = "error-message";

    private const string template = _("""# Failed to connect

```
    Λ
___/ \___
‛𑑍     _   ⸲’     Failed to connect 🔌️
 /,” ‛⹁\
/’    ‛\
```

Failed to connect to the page at ${uri}. This may be caused by issues with your internet connection, page's domain or the server serging the page. To proceed you can:

* Check your internet connection.
* Check that Starfish app has permission to access network.
* Check that domain ${domain} is correct.
* Go back to the last visited page.
* Try reloading this page now.
* Try visiting this page later.

Technical details:

```

Loacal error message

${error-message}

```
""");

    protected override string get_template () {
        return template;
    }
}

