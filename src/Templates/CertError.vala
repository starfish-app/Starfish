public class Starfish.Templates.CertError : Template {

        public static string URI_KEY = "uri";
        public static string STATUS_CODE_KEY = "status-code";
        public static string META_KEY = "meta";

    private const string template = _("""# Certificate required

```
    Λ
___/ \___
‛𑑍     _   ⸲’     Unsuported feature 🐣️
 /,” ‛⹁\
/’    ‛\
```

The page at ${uri} requires the use of client certificate. Ths is usually required in order for pod to shw you some personalized content. Unfortunatelly Starfish browser doesn't currently support this feature of the Gemini protoco. To proceed you can:

* Go back to the last visited page.
* Check if there's a newer version of Starfish to upgrade to.

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

