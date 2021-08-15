public class Starfish.Templates.UnsuportedSchema : Template {

        public static string URI_KEY = "uri";
        public static string PROTOCOL_KEY = "protocol";

    private const string template = _("""# Unsuported protocol

```
    Λ
___/ \___
‛𑑍     _   ⸲’     Unsuported protocol 🔮️
 /,” ‛⹁\
/’    ‛\
```

The page at ${uri} is served over ${protocol} protocol, which is not supported and cannot be opened. To proceed you can go back to the last visited page.

""");

    protected override string get_template () {
        return template;
    }
}

