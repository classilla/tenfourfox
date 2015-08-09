**This is for a beta release of TenFourFox and will be updated as new beta versions are posted, so check back here if you are having difficulty. If you want the regular version, _do not use_ this beta: it may have additional bugs. Please use version 31 in the meantime.**

## System requirements ##

TenFourFox (hereafter "10.4Fx") requires a G3 Power Macintosh, Mac OS X 10.4.11, 200MB of free disk space and 512MB of RAM. 1GB of RAM and a G4 or G5 processor is recommended. Video playback is likely to be poor on systems slower than 1.25GHz; a G5 is recommended. Mac OS X 10.5.8 is supported. Although the browser may run under Mac OS X Server, it is not currently supported.

Intel Macintoshes are not supported. Although some users have reported success getting the G3 version of 10.4Fx to run under Rosetta, certain features may not work correctly or at all on Intel Macs, and you may need to completely disable JavaScript compilation for it to work with Rosetta (see [the FAQ](AAATheFAQ.md) for more information). Because Apple no longer supports Rosetta and 10.4Fx is not a Universal binary, it will not run under Lion 10.7 or any subsequent version of Mac OS X.

## Getting TenFourFox ##

Make sure you select the appropriate build for your Mac from the [download page](http://www.tenfourfox.com/). The G3 version will run on any supported Macintosh, but it will not take advantage of the additional features of G4 or G5 processors. The G4 and G5 versions will not run at all on a G3, and the G5 version will perform badly or crash on non-G5 Macintoshes.

**Starting with 24.1.0, all downloads are hosted on SourceForge due to Google Code's download restrictions.** We strongly recommend getting the most recent version directly from [the main TenFourFox website](http://www.tenfourfox.com/), but you can also browse files in the [TenFourFox SourceForge repository](https://sourceforge.net/projects/tenfourfox/files/) if you prefer.

If you are using a G4, you should try to choose the correct version for your processor generation (7400 or 7450 "G4e") as performance may be impaired if you run the wrong one. If you don't know which G4 processor you have, the instructions in WhichVersion will tell you how to find out.

## TenFourFox 38 is equivalent to Firefox 38 ##

TenFourFox uses modified Firefox source code, rewritten to remain compatible with Mac OS X v10.4 and the Power Macintosh. It also contains specific optimizations and special features for PowerPC processors. For this reason, it is not exactly the same as Firefox. However, it is intended to be as compatible with it as possible, including most add-ons and [most standard features](TechnicalDifferences.md). You can treat 10.4Fx 38 as equivalent with Firefox 38 in most circumstances, with specific exceptions noted below.

Note that add-ons which require an Intel Macintosh will not work with TenFourFox, even if they are otherwise compatible with Firefox 38, and add-ons that require 10.5 Leopard (or higher) may not be compatible with TenFourFox running on Mac OS X 10.4 Tiger, even if they are compatible with PowerPC.

## This branch of TenFourFox is the _new_ stable version ##

Starting with Firefox 10, Mozilla began offering an extended support release version of Firefox ("Firefox **ESR**") intended for environments where users are unable to use rapid-release versions of Firefox due to policy or technical constraints. This ESR is the basis of the TenFourFox **stable** branch.

The current ESR release is based on Firefox 38. 10.4Fx 38.x is based on this extended support release and is intended for users who wish to remain with a stable browser core. The stable branch will continue to receive bugfixes and security updates, but will not receive new Firefox features (although it may receive certain 10.4Fx-specific features judged important for our legacy users).

**We recommend this version for most of our users.** If you wish to help test our continuing porting efforts, you can try the _unstable_ branch, which is based on the current release of Firefox. _The unstable branch does have bugs and is recommended only for advanced users._ For more information, see the [TenFourFox Development](http://tenfourfox.blogspot.com/) blog.

## TenFourFox no longer supports plugins or Flash ##

Plugins on PowerPC are of special concern because Mozilla is making updates to their plugin architecture which may require the plugins themselves to be updated, and there are certain difficult-to-correct bugs with them already on Tiger. Most importantly, QuickTime, Java and Adobe Flash for PowerPC are no longer maintained and have known security risks that can crash, perform malicious operations or leak data, and Flash 10.1 is rapidly becoming unsupported by many applications.

**For these and other reasons (for details, see PluginsNoLongerSupported), TenFourFox does not run plugins and they cannot be enabled.** Bug reports will no longer be accepted. Sites will now act as if no plugins were installed at all. Earlier versions that allowed an undocumented plugin support mode are no longer supported.

For Internet video, we now recommend the use of TenFourFox's optional QuickTimeEnabler. This allows many videos to be handled in QuickTime Player directly.

You can also download videos for separate viewing using [Perian](http://www.perian.org/) and any of the available video download add-ons for Firefox.

If you have a high end G4 or G5, you can also use WebM for selected videos by visiting http://www.youtube.com/html5 and enabling HTML5 video. This will set a temporary cookie enabling browser-based video without Flash. You do not need a YouTube account for this feature, but you may need to periodically renew the cookie setting. Not all video is available in WebM.

For a more in-depth explanation of this policy and other workarounds, see PluginsNoLongerSupported.

## New in this version of TenFourFox ##

  * All standard supported features of Firefox 38, including in-browser PDF viewing, Reader View for simplified and faster loading pages, in-content preferences, enhanced memory management and garbage collection, and multiple improvements to HTML5/CSS performance and compatibility.
  * TenFourFox's new custom IonPower JavaScript backend accelerates JavaScript operations by up to eleven times over version 31, and up to over 40 times faster than the basic interpreter ([issue 178](https://code.google.com/p/tenfourfox/issues/detail?id=178)).
  * Local font attributes are now cached more aggressively, improving text rendering performance.
  * Full colour management is enabled for all images.

## Bugs fixed in this beta of TenFourFox ##

  * The browser no longer crashes when enumerating webfonts for cleanup.
  * The browser no longer crashes on 10.5 systems while viewing certain New York Times websites with non-standard webfonts. This issue also affects 31.8, and can cause 10.4 systems to display unusual error messages. A general font URL blacklist has been internally implemented for future use.
  * Issues with JavaScript malfunctioning on Facebook and Facebook-derived sites such as Instagram have been corrected.
  * Saved passwords now correctly appear in preferences ([issue 305](https://code.google.com/p/tenfourfox/issues/detail?id=305)).
  * Checkmarks now correctly appear on context and drop-down menus.
  * Basic JavaScript internationalization support is implemented for add-ons that may require it ([issue 266](https://code.google.com/p/tenfourfox/issues/detail?id=266)). This issue also affects 31.8.

## Known issues specific to TenFourFox ##

  * Remember: **Plugins do not work in TenFourFox and can no longer be enabled.** See PluginsNoLongerSupported for an explanation and suggested workarounds.
  * Starting in version 38, the `Check for Updates` menu option is now under the Help menu, as in the official Mac Firefox.
  * Starting in version 38, the new tab page is always blank.
  * Starting in version 38, the default search provider is now Yahoo, not Google. You can change it back from the preferences page.
  * TenFourFox intentionally uses a lighter chrome for windows and dialogue boxes than prior versions or the official Mac Firefox.
  * Bitmap-only fonts (usually Type 1 PostScript) cannot be used by the 10.4Fx font renderer and are automatically ignored by the browser. A fallback font will be used in their place.
  * Personas and certain custom skins may hide the "traffic light" window buttons, but they are still present and will work if hovered over or clicked on ([issue 247](https://code.google.com/p/tenfourfox/issues/detail?id=247)).
  * The "traffic light" buttons are misplaced on private browsing windows if the title bar is enabled (not the default). They function normally otherwise.
  * Not all webcams are supported; in addition, multiple webcams may not all appear depending on how they are connected ([issue 221](https://code.google.com/p/tenfourfox/issues/detail?id=221)). For a list of supported webcam devices, see VideoDeviceSupport.
  * 10.4Fx does not currently support WebGL, WebRTC or the webapp runtime, and scripts such as Arabic or Indic requiring glyph reordering or language-specific ligatures may not appear correctly without OpenType fonts. See TechnicalDifferences for the complete list of changes necessary for 10.4Fx. See [issue 5](https://code.google.com/p/tenfourfox/issues/detail?id=5) for notes specific to the font issue.
  * Printing may crash the browser on Mac OS X Tiger Server ([issue 279](https://code.google.com/p/tenfourfox/issues/detail?id=279)). Please note that Mac OS X Server is not supported currently.
  * Crash reporting is intentionally disabled to avoid polluting Mozilla's crash tracking system with our reports. Please use your system's crash logs if you are reporting a _reproducible_ crash, or (if you are able) provide a `gdb` backtrace.
  * Although 10.4Fx will tell you when an update is available, you must download updates manually at this time.

You are welcome to report other bugs that you find. However, please **do not report Mozilla bugs to us.** If the bug or crash occurs in both the official Mozilla Firefox 38 _(3.6 doesn't count!)_ and in 10.4Fx, this is a Mozilla bug, and you should file it at [Bugzilla](http://bugzilla.mozilla.org/). **You must test your bug in both places -- bugs that are not confirmed to be part of 10.4Fx will be marked invalid** so that we can keep our task list focused. This is the [current list of known issues](http://code.google.com/p/tenfourfox/issues/list).