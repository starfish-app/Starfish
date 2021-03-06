public class Starfish.Templates.TempFailure : Template {

        public static string URI_KEY = "uri";
        public static string STATUS_CODE_KEY = "status-code";
        public static string META_KEY = "meta";

    private const string template = _("""# Temporary faliure

```
    Ξ
___/ \___
βπ     _   βΈ²β     Temporary faliure β³οΈ
 /,β ββΉ\
/β    β\
```

There was a temporary issue with loading the page at ${uri}. The issue is on the server side. To proceed you can:

* Go back to the last visited page.
* Try reloading this page now.
* Try visiting this page later.

Technical details:

```

Gemini response details

<STATUS>: ${status-code}

<META>: ${meta}

```
""");

    protected override string get_template () {
        return template;
    }
}

