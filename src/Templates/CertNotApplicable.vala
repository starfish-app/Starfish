public class Starfish.Templates.CertNotApplicable : Template {

        public static string URI_KEY = "uri";
        public static string HOST_KEY = "host";

    private const string template = _("""# Certificate is not applicable

```
    Λ
___/ \___
‛𑑍     _   ⸲’     Certificate is not applicable 🎭️
 /,” ‛⹁\
/’    ‛\
```

The page at ${uri} provided a certificate that is not applicable to its own domain ${host}. This is a mistake on the server's side and it will need to be fixed there. To proceed you can:

* Go back to the last visited page.
* Try visiting this page again later.

""");

    protected override string get_template () {
        return template;
    }
}

