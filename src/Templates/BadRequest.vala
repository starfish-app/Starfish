public class Starfish.Templates.BadRequest : Template {

        public static string URI_KEY = "uri";
        public static string DOMAIN_KEY = "domain";
        public static string STATUS_CODE_KEY = "status-code";
        public static string META_KEY = "meta";

    private const string template = _("""# Bad request

```
    Λ
___/ \___
‛𑑍     _   ⸲’     Bad request 🗳️
 /,” ‛⹁\
/’    ‛\
```

Gemini pod at ${domain} cannot process the request to load page at ${uri}. This may be because of an invalid input value, or unsuported proxy feature on the server. To proceed you can:

* Go back to the last visited page.
* In case you provided input check its value.

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

