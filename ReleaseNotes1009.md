_This document may be updated for late-breaking changes, so check back here if you are having difficulty._

## System requirements ##

TenFourFox (hereafter "10.4Fx") requires a G3 Power Macintosh, Mac OS X 10.4.11, 100MB of free disk space and 512MB of RAM. 1GB of RAM and a G4 or G5 processor is recommended. Video playback is likely to be poor on systems slower than 1.25GHz; a G5 is recommended. Mac OS X 10.5.8 is supported.

Intel Macintoshes are not supported, but the G3 build is known to run under Rosetta in 10.4.11, 10.5.8 and 10.6.8. Because Apple no longer supports Rosetta and 10.4Fx is not a Universal binary, it will not run under Lion 10.7 or any future version of Mac OS X.

## Getting TenFourFox ##

Make sure you select the appropriate build for your Mac from the [download page](http://www.tenfourfox.com/). The G3 version will run on any supported Macintosh, but it will not take advantage of the additional features of G4 or G5 processors. The G4 and G5 versions will not run correctly if at all on a G3, and the G5 version will perform badly or crash on non-G5 Macintoshes.

If you are using a G4, you should try to choose the correct version for your processor generation (7400 or 7450 "G4e") as performance may be impaired if you run the wrong one. If you don't know which G4 processor you have, the instructions in WhichVersion will tell you how to find out.

## TenFourFox 10.0.x is equivalent to Firefox ESR 10.0.x ##

TenFourFox uses modified Firefox source code, rewritten to remain compatible with Mac OS X v10.4 and the Power Macintosh. It also contains specific optimizations and special features for PowerPC processors. For this reason, it is not exactly the same as Firefox. However, it is intended to be as compatible with it as possible, including most add-ons and [most standard features](TechnicalDifferences.md). You can treat 10.4Fx as equivalent with Firefox ESR 10.0 in most circumstances, with specific exceptions noted below.

Note that add-ons which require an Intel Macintosh will not work with TenFourFox, even if they are otherwise compatible with Firefox 10, and add-ons that require 10.5 Leopard may not be compatible with TenFourFox running on Mac OS X 10.4 Tiger, even if they are compatible with PowerPC.

## This branch of TenFourFox is the _stable_ version ##

Starting with Firefox 10, Mozilla is now offering an extended support release version of Firefox ("Firefox **ESR**") intended for environments where users are unable to use rapid-release versions of Firefox due to policy or technical constraints.

10.4Fx 10.x is based on this extended support release and is intended for users who wish to remain with a stable browser core. The stable branch will continue to receive bugfixes and security updates, but will not receive new Firefox features (although it may receive certain 10.4Fx-specific features judged important for our legacy users).

**We recommend this version for most of our users.** If you wish to help test our continuing porting efforts, you can try the _unstable_ branch, which is based on the current release of Firefox. _The unstable branch does have bugs and is recommended only for advanced users._ For more information, see the [TenFourFox Development](http://tenfourfox.blogspot.com/) blog.

## TenFourFox no longer supports plugins or Flash ##

Plugins on PowerPC are of special concern because Mozilla is making updates to their plugin architecture which may require the plugins themselves to be updated, and there are certain difficult-to-correct bugs with them already on Tiger. Most importantly, QuickTime and Adobe Flash for PowerPC are no longer maintained and have known security risks that can crash, perform malicious operations or leak data, and Flash 10.1 is rapidly becoming unsupported by many applications.

**As of TenFourFox 6.0, for these and other reasons (for details, see PluginsNoLongerSupported), plugin support ships disabled.** Plugins will not operate by default, and bug reports will no longer be accepted. Sites will now act as if no plugins were installed at all.

For Internet video, we now recommend the use of TenFourFox's optional QuickTimeEnabler. This allows many videos to be handled in QuickTime Player directly.

You can also download videos for separate viewing using [Perian](http://www.perian.org/) and any of the available video download add-ons for Firefox.

For YouTube, you may also be able to use [MacTubes](http://macapps.sakura.ne.jp/mactubes/index_en.html). If you have a high end G4 or G5, you can also use WebM for selected videos by visiting http://www.youtube.com/html5 and enabling HTML5 video. This will set a temporary cookie enabling browser-based video without Flash. You do not need a YouTube account for this feature, but you may need to periodically renew the cookie setting. Not all video is available in WebM.

For a more in-depth explanation of this policy and other workarounds, see PluginsNoLongerSupported.

## Known issues fixed in this version of TenFourFox ##

  * Fixes an urgent security issue in Firefox (Mozilla [bug 720619](https://code.google.com/p/tenfourfox/issues/detail?id=20619)). All users are strongly advised to upgrade as soon as possible.

## Known issues specific to TenFourFox ##

  * Remember: **Plugins are turned off by default, and code for them will fail to function entirely in a subsequent version.** See PluginsNoLongerSupported for an explanation and suggested workarounds. Please note that out-of-process plugins have never been supported.
  * As of TenFourFox 8, TenFourFox uses a lighter chrome for windows and dialogue boxes than prior versions or the official Mac Firefox. This is intentional.
  * When 10.4Fx has no suggestions for the awesome bar, a blank box appears instead ([issue 21](https://code.google.com/p/tenfourfox/issues/detail?id=21)). This is intentional.
  * 10.4Fx does not currently support WebGL, and scripts such as Indic or Arabic requiring glyph reordering or language-specific ligatures may not appear correctly. See TechnicalDifferences for the complete list of changes necessary for 10.4Fx. See [issue 5](https://code.google.com/p/tenfourfox/issues/detail?id=5) for notes specific to the font issue.
  * Animation performance is currently poorer in Mozilla 2.0/Firefox 4.0 and later versions using software rendering, which includes 10.4Fx. The later graphics stack in the unstable release improves greatly upon this issue, and will become available in the near future on the stable branch.
  * The titlebar does not always properly match the menu gradient ([issue 16](https://code.google.com/p/tenfourfox/issues/detail?id=16)). This problem is also in the official release. Installing a Persona may fix this issue if you find it bothersome.
  * Crash reporting is intentionally disabled to avoid polluting Mozilla's crash tracking system with our reports. Please use your system's crash logs if you are reporting a _reproducible_ crash, or (if you are able) provide a `gdb` backtrace.
  * Although 10.4Fx will tell you when an update is available, you must download updates manually at this time.

You are welcome to report other bugs that you find. However, please **do not report Mozilla bugs to us.** If the bug or crash occurs in both the official Mozilla Firefox 10 ESR _(3.6 doesn't count!)_ and in 10.4Fx, this is a Mozilla bug, and you should file it at [Bugzilla](http://bugzilla.mozilla.org/). **You must test your bug in both places -- bugs that are not confirmed to be part of 10.4Fx will be marked invalid** so that we can keep our task list focused. This is the [current list of known issues](http://code.google.com/p/tenfourfox/issues/list).