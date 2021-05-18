public class Starfish.Core.GeminiBodyTest : Starfish.TestBase, BodyTestBase, Object {

    public string get_base_path () {
        return "/Starfish/Gemini/GeminiBody/";
    }

    public Gee.Map<string, TestFunc> get_tests () {
        var tests = new Gee.HashMap<string, TestFunc> ();
        tests["should-properly-detect-line-types"] = should_properly_detect_line_types;
        return tests;
    }

    private static string GEMTEXT = """#H1 title
# H1 title with a space
##H2 title
## H2 title with a space
###H3 title
### H3 title with a space

Text line with actual text
* List item
>Quote
> Quote with space
```
```
```
# H1
## H2
### H3
Preformatted
* List item
> Quote
=> /link
```
```Alt text
```
``` Alt text with a space
```
```Alt text
Preformatted
```
``` Alt text with a space
Preformatted
```
=>
=> 
=>gemini://josipantolis.from.hr/starfish
=> gemini://josipantolis.from.hr/starfish
=>gemini://josipantolis.from.hr/starfish ⭐️ Starfish project
=> gemini://josipantolis.from.hr/starfish   ⭐️ Starfish project
=>/starfish
=> /starfish
=>/starfish ⭐️ Starfish project
=> /starfish   ⭐️ Starfish project
""";

    public static void should_properly_detect_line_types () {
        var given_in_stream = new MemoryInputStream.from_data (GEMTEXT.data);
        var mock_out_stream = new MemoryOutputStream.resizable ();
        var given_io_stream = new SimpleIOStream (given_in_stream, mock_out_stream);
        var body = new GeminiBody (new Mime ("text/gemini"), given_io_stream);
        var actual_lines = collect_lines_from (body);
        assert_line_arrays (
            actual_lines,
            {
                new Line ("#H1 title", LineType.HEADING_1),
                new Line ("# H1 title with a space", LineType.HEADING_1),
                new Line ("##H2 title", LineType.HEADING_2),
                new Line ("## H2 title with a space", LineType.HEADING_2),
                new Line ("###H3 title", LineType.HEADING_3),
                new Line ("### H3 title with a space", LineType.HEADING_3),
                new Line ("", LineType.TEXT),
                new Line ("Text line with actual text", LineType.TEXT),
                new Line ("* List item", LineType.LIST_ITEM),
                new Line (">Quote", LineType.QUOTE),
                new Line ("> Quote with space", LineType.QUOTE),
                new Line ("```", LineType.PREFORMATTED_START),
                new Line ("```", LineType.PREFORMATTED_END),
                new Line ("```", LineType.PREFORMATTED_START),
                new Line ("# H1", LineType.PREFORMATTED),
                new Line ("## H2", LineType.PREFORMATTED),
                new Line ("### H3", LineType.PREFORMATTED),
                new Line ("Preformatted", LineType.PREFORMATTED),
                new Line ("* List item", LineType.PREFORMATTED),
                new Line ("> Quote", LineType.PREFORMATTED),
                new Line ("=> /link", LineType.PREFORMATTED),
                new Line ("```", LineType.PREFORMATTED_END),
                new Line ("```Alt text", LineType.PREFORMATTED_START),
                new Line ("```", LineType.PREFORMATTED_END),
                new Line ("``` Alt text with a space", LineType.PREFORMATTED_START),
                new Line ("```", LineType.PREFORMATTED_END),
                new Line ("```Alt text", LineType.PREFORMATTED_START),
                new Line ("Preformatted", LineType.PREFORMATTED),
                new Line ("```", LineType.PREFORMATTED_END),
                new Line ("``` Alt text with a space", LineType.PREFORMATTED_START),
                new Line ("Preformatted", LineType.PREFORMATTED),
                new Line ("```", LineType.PREFORMATTED_END),
                new Line ("=>", LineType.TEXT),
                new Line ("=> ", LineType.TEXT),
                new Line ("=>gemini://josipantolis.from.hr/starfish", LineType.LINK),
                new Line ("=> gemini://josipantolis.from.hr/starfish", LineType.LINK),
                new Line ("=>gemini://josipantolis.from.hr/starfish ⭐️ Starfish project", LineType.LINK),
                new Line ("=> gemini://josipantolis.from.hr/starfish   ⭐️ Starfish project", LineType.LINK),
                new Line ("=>/starfish", LineType.LINK),
                new Line ("=> /starfish", LineType.LINK),
                new Line ("=>/starfish ⭐️ Starfish project", LineType.LINK),
                new Line ("=> /starfish   ⭐️ Starfish project", LineType.LINK)
            }
        );
    }
}

