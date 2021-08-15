public class Starfish.Templates.NonGeminiRedirect : Template {

        public static string URI_KEY = "uri";
        public static string REDIRECT_PROTOCOL_KEY = "redirect-protocol";
        public static string REDIRECT_URI_KEY = "redirect-uri";

    private const string template = _("""# Non Gemini redirect

```
    Λ
___/ \___
‛𑑍     _   ⸲’     Non Gemini redirect 🌐️
 /,” ‛⹁\
/’    ‛\
```

The page at ${uri} is attempting to automatically redirect you to a page served over ${redirect-protocol}, which will not open automatically. If you want you can open it yourself:

=> ${redirect-uri}

Or you can go back to the last visited page.

""");

    protected override string get_template () {
        return template;
    }
}

