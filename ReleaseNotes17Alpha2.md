_This document may be updated for late-breaking changes, so check back here if you are having difficulty._

## System requirements ##

TenFourFox (hereafter "10.4Fx") requires a G3 Power Macintosh, Mac OS X 10.4.11, 100MB of free disk space and 512MB of RAM. 1GB of RAM and a G4 or G5 processor is recommended. Video playback is likely to be poor on systems slower than 1.25GHz; a G5 is recommended. Mac OS X 10.5.8 is supported.

Intel Macintoshes are not supported, but the G3 build is known to run under Rosetta in 10.4.11, 10.5.8 and 10.6.8. Because Apple no longer supports Rosetta and 10.4Fx is not a Universal binary, it will not run under Lion 10.7 or any future version of Mac OS X.

## Getting TenFourFox ##

Make sure you select the appropriate build for your Mac from the [download page](http://www.tenfourfox.com/). The G3 version will run on any supported Macintosh, but it will not take advantage of the additional features of G4 or G5 processors. The G4 and G5 versions will not run at all on a G3, and the G5 version will perform badly or crash on non-G5 Macintoshes.

If you are using a G4, you should try to choose the correct version for your processor generation (7400 or 7450 "G4e") as performance may be impaired if you run the wrong one. If you don't know which G4 processor you have, the instructions in WhichVersion will tell you how to find out.

## TenFourFox 17 Alpha is equivalent to Firefox 17 Aurora ##

TenFourFox uses modified Firefox source code, rewritten to remain compatible with Mac OS X v10.4 and the Power Macintosh. It also contains specific optimizations and special features for PowerPC processors. For this reason, it is not exactly the same as Firefox. However, it is intended to be as compatible with it as possible, including most add-ons and [most standard features](TechnicalDifferences.md). You can treat 10.4Fx 17 as equivalent with Firefox 17 in most circumstances, with specific exceptions noted below.

Note that add-ons which require an Intel Macintosh will not work with TenFourFox, even if they are otherwise compatible with Firefox 17, and add-ons that require 10.5 Leopard may not be compatible with TenFourFox running on Mac OS X 10.4 Tiger, even if they are compatible with PowerPC.

## This branch of TenFourFox _will be_ the new stable version ##

Starting with Firefox 10, Mozilla is now offering an extended support release version of Firefox ("Firefox **ESR**") intended for environments where users are unable to use rapid-release versions of Firefox due to policy or technical constraints. This ESR is the basis of the TenFourFox **stable** branch. The _stable_ branch will continue to receive bugfixes and security updates, but will not receive new Firefox features (although it may receive certain 10.4Fx-specific features judged important for our legacy users).

The next Firefox ESR will be Firefox 17. **This is a preview early release of this new version which will become the next stable version of TenFourFox.** Please test it for the benefit of our other users so that we can identify bugs and serious issues early. Your testing helps make the browser better.

Please note: this is a preview release and _it has known bugs._ **If you need a release-quality version of TenFourFox, please use the 10.0.x stable version instead until this preview version matures.** You can download 10.0.x from [our main page](http://www.tenfourfox.com/).

## TenFourFox no longer supports plugins or Flash ##

Plugins on PowerPC are of special concern because Mozilla is making updates to their plugin architecture which may require the plugins themselves to be updated, and there are certain difficult-to-correct bugs with them already on Tiger. Most importantly, QuickTime, Java and Adobe Flash for PowerPC are no longer maintained and have known security risks that can crash, perform malicious operations or leak data, and Flash 10.1 is rapidly becoming unsupported by many applications.

**As of TenFourFox 6.0, for these and other reasons (for details, see PluginsNoLongerSupported), plugin support ships disabled.** Plugins will not operate by default, and bug reports will no longer be accepted. Sites will now act as if no plugins were installed at all.

For Internet video, we now recommend the use of TenFourFox's optional QuickTimeEnabler. This allows many videos to be handled in QuickTime Player directly.

You can also download videos for separate viewing using [Perian](http://www.perian.org/) and any of the available video download add-ons for Firefox.

For YouTube, you may also be able to use [MacTubes](http://macapps.sakura.ne.jp/mactubes/index_en.html).  If you have a high end G4 or G5, you can also use WebM for selected videos by visiting http://www.youtube.com/html5 and enabling HTML5 video. This will set a temporary cookie enabling browser-based video without Flash. You do not need a YouTube account for this feature, but you may need to periodically renew the cookie setting. Not all video is available in WebM.

For a more in-depth explanation of this policy and other workarounds, see PluginsNoLongerSupported.

## New features in this new stable version of TenFourFox ##

  * All supported standard features of Firefox 11 through Firefox 17, including improved JavaScript performance, CoreGraphics accelerated canvas, faster screen updates, additional HTML5 and CSS 3 features, SPDY-enhanced encrypted networking, a smarter URL bar, integrated downloads and new web developer features.

## Known problems in this version of TenFourFox ##

  * Canvas elements sometimes do not properly update ([issue 180](https://code.google.com/p/tenfourfox/issues/detail?id=180), Mozilla [bug 794337](https://code.google.com/p/tenfourfox/issues/detail?id=94337)).

## Fixed in this version of TenFourFox ##

  * It is now possible to blacklist Arial, Helvetica and/or Times (or any other combination) for users with corrupt or abnormal versions of these fonts ([issue 171](https://code.google.com/p/tenfourfox/issues/detail?id=171)). See [this Tenderapp ticket](http://tenfourfox.tenderapp.com/discussions/problems/2-italic-display) for information about when and how to use this blacklist. This affects all versions of 10.4Fx, but will not be backported to 10.0.x due to differences in font code.
  * The No Thanks button in the update dialogue now works correctly ([issue 130](https://code.google.com/p/tenfourfox/issues/detail?id=130)). This affects 10 through 15. This fix will be backported to 10.0.8.
  * You can now search bookmarks again ([issue 177](https://code.google.com/p/tenfourfox/issues/detail?id=177)). This affects 13 through 15. This issue does not affect 10.0.x.

## Known issues specific to TenFourFox ##

  * Remember: **Plugins are turned off by default, and code for them will fail to function entirely in a subsequent version.** See PluginsNoLongerSupported for an explanation and suggested workarounds. Please note that out-of-process plugins have never been supported.
  * As of TenFourFox 8, TenFourFox uses a lighter chrome for windows and dialogue boxes than prior versions or the official Mac Firefox. This is intentional.
  * 10.4Fx does not currently support WebGL, WebRTC or the webapp runtime, and scripts such as Arabic or Indic requiring glyph reordering or language-specific ligatures may not appear correctly. See TechnicalDifferences for the complete list of changes necessary for 10.4Fx. See [issue 5](https://code.google.com/p/tenfourfox/issues/detail?id=5) for notes specific to the font issue.
  * The titlebar does not always properly match the menu gradient ([issue 16](https://code.google.com/p/tenfourfox/issues/detail?id=16)). This problem is also in the official release. Installing a Persona may fix this issue if you find it bothersome.
  * Crash reporting is intentionally disabled to avoid polluting Mozilla's crash tracking system with our reports. Please use your system's crash logs if you are reporting a _reproducible_ crash, or (if you are able) provide a `gdb` backtrace.
  * Although 10.4Fx will tell you when an update is available, you must download updates manually at this time.

You are welcome to report other bugs that you find. However, please **do not report Mozilla bugs to us.** If the bug or crash occurs in both the official Mozilla Firefox 17 _(3.6 doesn't count!)_ and in 10.4Fx, this is a Mozilla bug, and you should file it at [Bugzilla](http://bugzilla.mozilla.org/). **You must test your bug in both places -- bugs that are not confirmed to be part of 10.4Fx will be marked invalid** so that we can keep our task list focused. This is the [current list of known issues](http://code.google.com/p/tenfourfox/issues/list).