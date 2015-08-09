_This document may be updated for late-breaking changes, so check back here if you are having difficulty._

## System requirements ##

TenFourFox (hereafter "10.4Fx") requires a G3 Power Macintosh, Mac OS X 10.4.11, 100MB of free disk space and 512MB of RAM. 1GB of RAM and a G4 or G5 processor is recommended. Video playback is likely to be poor on systems slower than 1.25GHz; a G5 is recommended. Mac OS X 10.5.8 is supported.

Intel Macintoshes are not supported. Although some users have reported success getting the G3 version of 10.4Fx to run under Rosetta, certain features may not work correctly or at all on Intel Macs, and you may need to completely disable JavaScript compilation for it to work with Rosetta (see [the FAQ](AAATheFAQ.md) for more information). Because Apple no longer supports Rosetta and 10.4Fx is not a Universal binary, it will not run under Lion 10.7 or any subsequent version of Mac OS X.

## Getting TenFourFox ##

Make sure you select the appropriate build for your Mac from the [download page](http://www.tenfourfox.com/). The G3 version will run on any supported Macintosh, but it will not take advantage of the additional features of G4 or G5 processors. The G4 and G5 versions will not run at all on a G3, and the G5 version will perform badly or crash on non-G5 Macintoshes.

If you are using a G4, you should try to choose the correct version for your processor generation (7400 or 7450 "G4e") as performance may be impaired if you run the wrong one. If you don't know which G4 processor you have, the instructions in WhichVersion will tell you how to find out.

## TenFourFox 19 is equivalent to Firefox 19 ##

TenFourFox uses modified Firefox source code, rewritten to remain compatible with Mac OS X v10.4 and the Power Macintosh. It also contains specific optimizations and special features for PowerPC processors. For this reason, it is not exactly the same as Firefox. However, it is intended to be as compatible with it as possible, including most add-ons and [most standard features](TechnicalDifferences.md). You can treat 10.4Fx 19 as equivalent with Firefox 19 in most circumstances, with specific exceptions noted below.

Note that add-ons which require an Intel Macintosh will not work with TenFourFox, even if they are otherwise compatible with Firefox 19, and add-ons that require 10.5 Leopard may not be compatible with TenFourFox running on Mac OS X 10.4 Tiger, even if they are compatible with PowerPC.

## This branch of TenFourFox is the _unstable_ version ##

Starting with Firefox 10 and now Firefox 17, Mozilla is now offering an extended support release version of Firefox ("Firefox **ESR**") intended for environments where users are unable to use rapid-release versions of Firefox due to policy or technical constraints. 10.4Fx 17.x is based on this extended support release and is intended for users who wish to remain with a stable browser core. The _stable_ branch will continue to receive bugfixes and security updates, but will not receive new Firefox features (although it may receive certain 10.4Fx-specific features judged important for our legacy users).

However, for more proficient users who want to try more up-to-date features and help us test new builds of 10.4Fx based on current releases of Firefox, we make available the _unstable_ branch, which is this release. **While the unstable branch is generally suitable for day-to-day use, it does have bugs and is recommended only for advanced users.** Although major bugs will be repaired as promptly as possible, minor and even some moderate severity bugs might not be fixed on a particular timetable. The highest priority is to keep the port viable, which may mean diverting our limited time away from non-critical issues. **If you need a release-quality version of TenFourFox, please use the stable version instead.** You can download the stable version from [our main page](http://www.tenfourfox.com/).

## Plugins and Flash _do not work_ in TenFourFox ##

Plugins on PowerPC are of special concern because Mozilla is making updates to their plugin architecture which may require the plugins themselves to be updated, and there are certain difficult-to-correct bugs with them already on Tiger. Most importantly, QuickTime, Java and Adobe Flash for PowerPC are no longer maintained and have known security risks that can crash, perform malicious operations or leak data, and Flash 10.1 is rapidly becoming unsupported by many applications.

**Plugins no longer function at all as of 10.4Fx 19.0.** Due to irreversible internal browser changes, there is no way to reenable them. Pages that use plugins will show a warning box instead.

For Internet video, we now recommend the use of TenFourFox's optional QuickTimeEnabler. This allows many videos to be handled in QuickTime Player directly.

You can also download videos for separate viewing using [Perian](http://www.perian.org/) and any of the available video download add-ons for Firefox.

For YouTube, you may also be able to use [MacTubes](http://macapps.sakura.ne.jp/mactubes/index_en.html).  If you have a high end G4 or G5, you can also use WebM for selected videos by visiting http://www.youtube.com/html5 and enabling HTML5 video. This will set a temporary cookie enabling browser-based video without Flash. You do not need a YouTube account for this feature, but you may need to periodically renew the cookie setting. Not all video is available in WebM.

For a more in-depth explanation of this policy and other workarounds, see PluginsNoLongerSupported.

## Fixed in this version of TenFourFox ##

  * This release fixes a high-priority Mozilla security issue (Mozilla [bug 848644](https://code.google.com/p/tenfourfox/issues/detail?id=48644)).
  * A potential crash is repaired in the JavaScript compiler ([issue 211](https://code.google.com/p/tenfourfox/issues/detail?id=211)).
  * Restoring bookmarks from Safari should work again ([issue 194](https://code.google.com/p/tenfourfox/issues/detail?id=194)).

**Please note that there was no 19.0.1 release; that version was reserved for mobile Firefox only.**

## Known issues specific to TenFourFox ##

  * Remember: **Plugins do not function in TenFourFox.** See PluginsNoLongerSupported for an explanation and suggested workarounds.
  * TenFourFox uses a lighter chrome for windows and dialogue boxes than prior versions or the official Mac Firefox. This is intentional.
  * Bitmap-only fonts (usually Type 1 PostScript) cannot be used by the 10.4Fx font renderer and are discarded. A fallback font will be used in their place.
  * Due to poor performance on Power Macs, the `PDF.js` PDF viewer is not enabled by default. (It can be turned on from `about:config`.)
  * 10.4Fx does not currently support WebGL, WebRTC or the webapp runtime, and scripts such as Arabic or Indic requiring glyph reordering or language-specific ligatures may not appear correctly. See TechnicalDifferences for the complete list of changes necessary for 10.4Fx. See [issue 5](https://code.google.com/p/tenfourfox/issues/detail?id=5) for notes specific to the font issue.
  * The titlebar does not always properly match the menu gradient ([issue 16](https://code.google.com/p/tenfourfox/issues/detail?id=16)). This problem is also in the official release. Installing a Persona may fix this issue if you find it bothersome.
  * Crash reporting is intentionally disabled to avoid polluting Mozilla's crash tracking system with our reports. Please use your system's crash logs if you are reporting a _reproducible_ crash, or (if you are able) provide a `gdb` backtrace.
  * Although 10.4Fx will tell you when an update is available, you must download updates manually at this time.

You are welcome to report other bugs that you find. However, please **do not report Mozilla bugs to us.** If the bug or crash occurs in both the official Mozilla Firefox 19 _(3.6 doesn't count!)_ and in 10.4Fx, this is a Mozilla bug, and you should file it at [Bugzilla](http://bugzilla.mozilla.org/). **You must test your bug in both places -- bugs that are not confirmed to be part of 10.4Fx will be marked invalid** so that we can keep our task list focused. This is the [current list of known issues](http://code.google.com/p/tenfourfox/issues/list).