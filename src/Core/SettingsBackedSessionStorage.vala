public class Starfish.Core.SettingsBackedSessionStorage : Object, SessionStorage {

    private static string SETTING_KEY = "sessions";

    public Settings settings { get; construct; }

    public SettingsBackedSessionStorage (Settings settings) {
        Object (settings: settings);
    }

    public Variant load () {
        return settings.get_value (SETTING_KEY);
    }

    public void save (Variant session) {
        settings.set_value (SETTING_KEY, session);
    }
}

