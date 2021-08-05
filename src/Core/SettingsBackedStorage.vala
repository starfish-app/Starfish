public class Starfish.Core.SettingsBackedStorage : Object, Storage {

    private static string SETTING_KEY = "sessions";
    private static string HOMEPAGE_KEY = "homepage";
    private static string FOCUSED_TAB_KEY = "focused-tab";
    private static string TABS_KEY = "tabs";

    public Settings settings { get; construct; }

    public SettingsBackedStorage (Settings settings) {
        Object (settings: settings);
    }

    public string load_homepage () {
        return settings.get_string (HOMEPAGE_KEY);
    }

    public void save_homepage (string homepage) {
        settings.set_string (HOMEPAGE_KEY, homepage);
    }

    public Variant load_sessions () {
        return settings.get_value (SETTING_KEY);
    }

    public void save_sessions (Variant session) {
        if (Granite.Services.System.history_is_enabled ()) {
            settings.set_value (SETTING_KEY, session);
        }
    }

    public int load_focused_tab () {
        return settings.get_int (FOCUSED_TAB_KEY);
    }

    public void save_focused_tab (int focused_tab) {
        if (Granite.Services.System.history_is_enabled ()) {
            settings.set_int (FOCUSED_TAB_KEY, focused_tab);
        }
    }

    public string[] load_tabs () {
        return settings.get_strv (TABS_KEY);
    }

    public void save_tabs (string[] tabs) {
        if (Granite.Services.System.history_is_enabled ()) {
            settings.set_strv (TABS_KEY, tabs);
        }
    }
}

