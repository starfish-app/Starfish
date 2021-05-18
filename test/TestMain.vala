public class Starfish.TestMain {

    public static int main (string[] args) {
        Test.init (ref args);
        add_tests ();
        Test.run ();
        return 0;
    }

    private static void add_tests () {
        Starfish.TestBase[] tests = {
            new Starfish.Core.MimeTest (),
            new Starfish.Core.ResponseTest (),
            new Starfish.Core.LineTest (),
            new Starfish.Core.TextBodyTest (),
            new Starfish.Core.GeminiBodyTest (),
            new Starfish.Core.UriTest ()
        };

        foreach (var test in tests) {
            var base_path = test.get_base_path ();
            var test_methods = test.get_tests ();
            foreach (var entry in test_methods) {
                var path = base_path + entry.key;
                Test.add_func (path, entry.value);
            }
        }
    }
}

