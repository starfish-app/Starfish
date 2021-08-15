public class Starfish.Templates.InvalidResponse : Template {

        public static string URI_KEY = "uri";
        public static string ERROR_MESSAGE_KEY = "error-message";

    private const string template = _("""# Received an invalid response

```
    Λ
___/ \___
‛𑑍     _   ⸲’     Received an invalid response ⁉️
 /,” ‛⹁\
/’    ‛\
```

Received an invalid response from the server for the page ${uri}. This may be caused by a bug on the server, or an unsuported feature in the Starfish browser itself. To proceed you can:

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

