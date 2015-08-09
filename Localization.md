**How to localize TenFourFox and make a Langpack Installer**

**Summary of changes for 38:**

- All localization files have been moved from Mac OS to Resources in the application package.

- space constraints/truncated strings in the Prefs window are gone because of UI change (prefs moved to tab)

- Check for Updates… has bee moved to the Help menu; localization string remains in baseMenuOverlay.dtd.

- Addon Manager: Plugin section with warning about Plugin support is obsolete

- plugins.dtd> <!ENTITY installPlugin is obsolete



## Localization Guide ##

# 1. Things to have first #

- Existing recent Locale Installer app as an example to work with

- GUItar application for compression/decompression (recommended)

- Apple TextEdit with preferences set to open/save in UTF-8 (or MacRoman if your language characters are supported)

- The TenFourFox version you want to localize

- Intel-Mac Firefox in your language corresponding to the TFF version. I.e. TFF 24.0 -> Firefox Intel 24.0. Please use the ESR version availabe here: http://www.mozilla.org/en-US/firefox/organizations/all.html


# 2. The installer application #

The installer application (incl. the installer script) has already been developed to a stable point.

Rename your installer application to e.g. "TFF-24-langpack-(your language).app" or the like so that people can see which exact version of TFF it is for, and which language the browser is changed to. Strings between sub-versions of the browser (24.0.0->24.0.1) are usually frozen, so the same installer app can be used. An installer for 17 cannot be used for 24 etc.

**The installer app's Package Contents folder contains:**

- the tarball file for the supported versions of TFF that can be localized with this installer. (see Tarball section).

- osx\_install.applescript (see applescript section)

- /Resources/TFFlang.icns: You can change that to your country's flag in Photoshop or just use the generic TFF icon or whatever.

- Info.plist: Change strings inside to the TFF version that is supported.

- TenFourFox de/fr (change name to your language). This is the executable that starts bash and the applescript.


# 3. The tarball file #

tarball.tar.bz2 has a compressed Contents folder. Don't confuse it with the installer application's Contents folder. Use OSX unzip (built-in) or GUItar.app to decompress. Note that it's double compressed in tar and bz2. This Contents folder contains the files that will replace the en-US locale originals in TenFourFox.app, or will be added to the originals:

Contents/Resources

/browser ->1)

/chrome ->2)

/chrome.manifest

/dictionaries ->3)


1)

chrome ->4)

chrome.manifest

defaults/preferences/firefox-l10n.js


2)

(your language)/locale/…

(your language).manifest


3)

(your language).aff

(your language).dic


4)

(your language)/locale/…

(your language).manifest



For creating the tar.bz2 archive: Compress your "Contents" folder in tar, then compress your Contents.tar archive in bz2. You can use GUItar.app to do this. Rename it to "tarball.tar.bz2".


# 4. The manifests #

There are two chrome manifests: in Resources/browser and in Resources.
In chrome.manifest one line must be changed:
manifest chrome/en-US.manifest -> (your language). For your language, use fr (French), ru (Russian) and so on. Use a double name (en-US, en-GB etc.) only when there are different country versions for the same language. Keep the language abbreviation consistent throughout the localization process, e.g. ru.manifest, "ru" folder in your folder tree etc.

There are two (your language) manifests: in Resources/browser/chrome  an in Resources/chrome. Copy the two respective en-US.manifest files from TFF and rename (your language).manifest. Inside change all strings accordingly.

Always use the original (!) manifest files from the TFF version you want to translate. Never copy them from the Intel version or any other version of the installer app, otherwise you will run into trouble.



# 5. The dictionaries #

Most languages in recent Firefox versions don't package the traditional dictionary files anymore (but TFF does). You will have to extract those from old FF 3.6.x in your language or download them from https://addons.mozilla.org/En-us/firefox/language-tools/. Note that both the .dic file and the .aff files are necessary.


# 6. l10n.js #

browser/defaults/preferences/firefox-l10n.js must be changed to your language. This is necessary so that browser extensions will speak your language if the programmer included them, otherwise they will stay English.

pref("general.useragent.locale", "(your language)");


# 7. Localization Strings taken from Intel-Firefox #

The localization strings are located within two folder trees within the TFF application package: Contents/Resources/Chrome/(language) and Contents/Resources/browser/chrome/(language). Have a look at the en-US folders in TFF first. You will need some of the files and strings inside later. The installer script copies your language folder tree from the installer app to TFF, so that the browser will have the folders for en-US (inactive) and (your language) (active) in the end.

1) Download the corresponding Intel version of FF and get the two omni.ja files from its application contents folder (Firefox uses a compressed jar format, while TFF doesn't). Rename to "omni.zip". Omni has a special zip format that Mac OS X itself might be unable to decompress. You can use the application GUItar for that.

2) Recreate the en-US folder tree within TFF in your language. Copy/replace all of them to your contents folder except the custom strings (if you're unsure, download an existing TFF 24+ installer app and look inside).

To edit the files, you can use Apple's TextEdit. Set Open and Save to UFT-8 in the preferences.

Note: The folder trees is the hardest thing to make. Be prepared to spend some time. If your tree doesn't work at first, try copying only some new string files/folders at a time to see at which point it's messed up. Always check if the edited files in the FF Intel version of your language, the TFF version of your language and the TFF en-US version are consistent.


# 8. TFF custom strings #

Some strings differ from the Intel Firefox version because we have our own update system and we don't support plugins.

browser/chrome/(language)/locale/browser/baseMenuOverlay.dtd (add Check for updates… string in your language to the Intel file)

browser/chrome/(language)/locale/branding/brand.dtd, brand.properties: Tenfourfox instead of Firefox; look at the original TFF file as an example and edit the Intel files accordingly, minus trademarkInfo in brand.dtd (<!ENTITY  trademarkInfo.part1   " ">)
Leave homePageSingleStartMain as is.

chrome/(language)/locale/(language)/mozapps/update/updates.dtd (manual update strings; edit the Intel file and translate&add these strings from the original TFF file)
(manualupdate2/3)

chrome/(language)/locale/(language)/mozapps/plugins/plugins.dtd
<!ENTITY missingPlugin                                       "TenFourFox does not support plugins for this content.">

chrome/(language)/locale/(language)/global/videocontrols.dtd:
instead of <!ENTITY error.srcNotSupported "Video format or MIME type is not supported.">
use <!ENTITY error.srcNotSupported "To play, ensure QuickTime Enabler is installed, then right-click and select Open Media in QuickTime."> in your language.

browser/chrome(language)locale/browser/aboutDialog.dtd (TFF's own dialog, use that instead of the Intel FF's which is incompatible. Translate the strings (it's sufficient to translate the strings that are actually shown in TFF. We don't use the update mechanism in the dialog.) ((in Aurora/Alpha versions, the About dialog will show different strings, check that you translated all of them, or just leave them English since this version won't go public anyway.))


# 9. The applescript #

The script does the automatic replacing and re-writing in the TFF.app and FF user profile. This script was originally taken and modified from the Open(Libre)Office langpack installer.

Translate the UI strings to your language. Also change the stated TFF version(s) to the correct one(s) in:

- set intro to

- set TFFVersions to

The script does the following things:

- Quits TFF if it's running

- Looks for TFF.app(s) and lets the user choose one if applicable

- Checks if TFF version is correct (i.e. is one of the version(s) supported by this installer app)

- Adds localization files to TFF app plus both (your language).manifest plus dictionaries

- Replaces both chrome.manifest

- Looks for user profile(s) in ~/Application Support/Firefox and writes general.useragent.locale (your language) in prefs.js