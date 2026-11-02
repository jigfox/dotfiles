// Zen profile prefs managed by chezmoi, applied on every start (shared by all profiles)

// load chrome/userChrome.css (duskfox theme)
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
// dark UI and dark websites, like the rest of the setup
user_pref("zen.view.window.scheme", 0);
user_pref("layout.css.prefers-color-scheme.content-override", 0);
