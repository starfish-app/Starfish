public class Starfish.Templates.PermFailure : Template {

        public static string URI_KEY = "uri";
        public static string STATUS_CODE_KEY = "status-code";
        public static string META_KEY = "meta";

    private const string template = _("""# Permanent faliure

```
    Λ
___/ \___
‛𑑍     _   ⸲’     Permanent faliure 💩️
 /,” ‛⹁\
/’    ‛\
```

There was a temporary issue with loading the page at ${uri}. The issue is on the server side. Reloading the same page in the future will not work. To proceed you can go back to the last visited page.

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

