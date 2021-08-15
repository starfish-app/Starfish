public class Starfish.Templates.Bookmarks : Template {

    public static string PARENT_DIRECTORY_KEY = "parent-directory";

    private const string template = _("""# Bookmarks

These are links to Gemini pages bookmarked from the Starfish browser. You can add or remove links from the Starfish app or by editing this page manually. You can find this file at:

=> file://${parent-directory}

Some usefull links (feel free to remove these):

=> gemini://gemini.circumlunar.space/capcom/ CAPCOM, an agregator of Gemini content

=> gemini://geminispace.info/ Geminispace.info, a search engine

=> gemini://josipantolis.from.hr/starfish/ Starfish project's home page

Your bookmarks:
""");

    protected override string get_template () {
        return template;
    }
}

