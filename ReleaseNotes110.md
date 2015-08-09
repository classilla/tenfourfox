_This document may be updated for late-breaking changes, so check back here if you are having difficulty._

## System requirements ##

TenFourFox (hereafter "10.4Fx") requires a G3 Power Macintosh, Mac OS X 10.4.11, 100MB of free disk space and 512MB of RAM. 1GB of RAM and a G4 or G5 processor is recommended. Video playback is likely to be poor on systems slower than 1.25GHz; a G5 is recommended. Mac OS X 10.5.8 is supported.

Intel Macintoshes are not supported, but the G3 build is known to run under Rosetta in 10.4.11, 10.5.8 and 10.6.8. Because Apple no longer supports Rosetta and 10.4Fx is not a Universal binary, it will not run under Lion 10.7 or any future version of Mac OS X.

## Getting TenFourFox ##

Make sure you select the appropriate build for your Mac from the [download page](http://www.tenfourfox.com/). The G3 version will run on any supported Macintosh, but it will not take advantage of the additional features of G4 or G5 processors. The G4 and G5 versions will not run correctly on a G3, and the G5 version will perform worse on non-G5 Macintoshes.

If you are using a G4, you should try to choose the correct version for your processor generation (7400 or 7450 "G4e") as performance may be impaired if you run the wrong one. If you don't know which G4 processor you have, the instructions in WhichVersion will tell you how to find out.

## TenFourFox 11 is equivalent to Firefox 11 ##

TenFourFox uses modified Firefox source code, rewritten to remain compatible with Mac OS X v10.4 and the Power Macintosh. It also contains specific optimizations and special features for PowerPC processors. For this reason, it is not exactly the same as Firefox. However, it is intended to be as compatible with it as possible, including most add-ons and [most standard features](TechnicalDifferences.md). You can treat 10.4Fx 11 as equivalent with Firefox 11 in most circumstances, with specific exceptions noted below.

Note that add-ons which require an Intel Macintosh will not work with TenFourFox, even if they are otherwise compatible with Firefox 11, and add-ons that require 10.5 Leopard may not be compatible with TenFourFox running on Mac OS X 10.4 Tiger, even if they are compatible with PowerPC.

## This branch of TenFourFox is the _unstable_ version ##

Starting with Firefox 10, Mozilla is now offering an extended support release version of Firefox ("Firefox **ESR**") intended for environments where users are unable to use rapid-release versions of Firefox due to policy or technical constraints. 10.4Fx 10.x is based on this extended support release and is intended for users who wish to remain with a stable browser core. The _stable_ branch will continue to receive bugfixes and security updates, but will not receive new Firefox features (although it may receive certain 10.4Fx-specific features judged important for our legacy users).

However, for more proficient users who want to try more up-to-date features and help us test new builds of 10.4Fx based on current releases of Firefox, we make available the _unstable_ branch, which is this release. **While the unstable branch is generally suitable for day-to-day use, it does have bugs and is recommended only for advanced users.** Although major bugs will be repaired as promptly as possible, minor and even some moderate severity bugs might not be fixed on a particular timetable. The highest priority is to keep the port viable, which may mean diverting our limited time away from non-critical issues. **If you need a release-quality version of TenFourFox, please use the stable version instead.** You can download the stable version from [our main page](http://www.tenfourfox.com/).

## TenFourFox no longer supports plugins or Flash ##

Plugins on PowerPC are of special concern because Mozilla is making updates to their plugin architecture which may require the plugins themselves to be updated, and there are certain difficult-to-correct bugs with them already on Tiger. Most importantly, QuickTime and Adobe Flash for PowerPC are no longer maintained and have known security risks that can crash, perform malicious operations or leak data, and Flash 10.1 is rapidly becoming unsupported by many applications.

**As of TenFourFox 6.0, for these and other reasons (for details, see PluginsNoLongerSupported), plugin support ships disabled.** Plugins will not operate by default, and bug reports will no longer be accepted. Sites will now act as if no plugins were installed at all.

For Internet video, we strongly recommend the use of [Perian](http://www.perian.org/) and any of the available video download add-ons for Firefox.

For YouTube, we recommend [MacTubes](http://macapps.web.infoseek.co.jp/mactubes/index_en.html). If you have a high end G4 or G5, you can also use WebM for selected videos by visiting http://www.youtube.com/html5 and enabling HTML5 video. This will set a temporary cookie enabling browser-based video without Flash. You do not need a YouTube account for this feature, but you may need to periodically renew the cookie setting. Not all video is available in WebM.

For a more in-depth explanation of this policy and other workarounds, see PluginsNoLongerSupported.

## New features in this version of TenFourFox ##

  * All new standard features of Firefox 11 where supported, including SPDY protocol support (disabled by default), battery API support, improved animated GIF performance, Graphite font compatibility, WebSockets improvements and new IndexedDB features.
  * Improved performance for G3 and G4 square root in JavaScript ([issue 134](https://code.google.com/p/tenfourfox/issues/detail?id=134)).
  * Improved G5 JavaScript overall performance ([issue 135](https://code.google.com/p/tenfourfox/issues/detail?id=135)).

## Known issues fixed in this version of TenFourFox ##

  * All bug fixes in [10.0.3 stable](ReleaseNotes1003.md) (except this version has a different square root routine).

## Known issues specific to TenFourFox ##

  * Remember: **Plugins are turned off by default, and code for them will fail to function entirely in a subsequent version.** See PluginsNoLongerSupported for an explanation and suggested workarounds. Please note that out-of-process plugins have never been supported.
  * As of TenFourFox 8, TenFourFox uses a lighter chrome for windows and dialogue boxes than prior versions or the official Mac Firefox. This is intentional.
  * When 10.4Fx has no suggestions for the awesome bar, a blank box appears instead ([issue 21](https://code.google.com/p/tenfourfox/issues/detail?id=21)). This is intentional.
  * 10.4Fx does not currently support WebGL, and Indic, Arabic and other scripts requiring glyph reordering or language-specific ligatures may not appear correctly. See TechnicalDifferences for the complete list of changes necessary for 10.4Fx. See [issue 5](https://code.google.com/p/tenfourfox/issues/detail?id=5) for notes specific to the font issue.
  * The titlebar does not always properly match the menu gradient ([issue 16](https://code.google.com/p/tenfourfox/issues/detail?id=16)). This problem is also in the official release. Installing a Persona may fix this issue if you find it bothersome.
  * Crash reporting is intentionally disabled to avoid polluting Mozilla's crash tracking system with our reports. Please use your system's crash logs if you are reporting a _reproducible_ crash, or (if you are able) provide a `gdb` backtrace.
  * Although 10.4Fx will tell you when an update is available, you must download updates manually at this time.

You are welcome to report other bugs that you find. However, please **do not report Mozilla bugs to us.** If the bug or crash occurs in both the official Mozilla Firefox 11 _(3.6 doesn't count!)_ and in 10.4Fx, this is a Mozilla bug, and you should file it at [Bugzilla](http://bugzilla.mozilla.org/). **You must test your bug in both places -- bugs that are not confirmed to be part of 10.4Fx will be marked invalid** so that we can keep our task list focused. This is the [current list of known issues](http://code.google.com/p/tenfourfox/issues/list).