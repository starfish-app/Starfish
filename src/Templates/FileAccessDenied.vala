public class Starfish.Templates.FileAccessDenied : Template {

        public static string PATH_KEY = "path";

    private const string template = _("""# Access to file denied

```
    Ξ
___/ \___
βπ     _   βΈ²β     Permissions denied ποΈ
 /,β ββΉ\
/β    β\
```

Starfish browser does not have the permissions to read the file ${path}. To proceed you can:

* Go back to the last visited page.
* Check if you have permissions to access the file.
* Check if Starfish app has permissions to access home and / or system folders.

""");

    protected override string get_template () {
        return template;
    }
}

