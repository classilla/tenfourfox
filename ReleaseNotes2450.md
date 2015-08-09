_This document may be updated for late-breaking changes, so check back here if you are having difficulty._

## System requirements ##

TenFourFox (hereafter "10.4Fx") requires a G3 Power Macintosh, Mac OS X 10.4.11, 100MB of free disk space and 512MB of RAM. 1GB of RAM and a G4 or G5 processor is recommended. Video playback is likely to be poor on systems slower than 1.25GHz; a G5 is recommended. Mac OS X 10.5.8 is supported.

Intel Macintoshes are not supported. Although some users have reported success getting the G3 version of 10.4Fx to run under Rosetta, certain features may not work correctly or at all on Intel Macs, and you may need to completely disable JavaScript compilation for it to work with Rosetta (see [the FAQ](AAATheFAQ.md) for more information). Because Apple no longer supports Rosetta and 10.4Fx is not a Universal binary, it will not run under Lion 10.7 or any subsequent version of Mac OS X.

## Getting TenFourFox ##

Make sure you select the appropriate build for your Mac from the [download page](http://www.tenfourfox.com/). The G3 version will run on any supported Macintosh, but it will not take advantage of the additional features of G4 or G5 processors. The G4 and G5 versions will not run at all on a G3, and the G5 version will perform badly or crash on non-G5 Macintoshes.

**Starting with 24.1.0, all downloads will be hosted on SourceForge due to Google Code's download restrictions.** We strongly recommend getting the most recent version directly from [the main TenFourFox website](http://www.tenfourfox.com/), but you can also browse files in the [TenFourFox SourceForge repository](https://sourceforge.net/projects/tenfourfox/files/) if you prefer.

If you are using a G4, you should try to choose the correct version for your processor generation (7400 or 7450 "G4e") as performance may be impaired if you run the wrong one. If you don't know which G4 processor you have, the instructions in WhichVersion will tell you how to find out.

## TenFourFox 24 is equivalent to Firefox 24 ##

TenFourFox uses modified Firefox source code, rewritten to remain compatible with Mac OS X v10.4 and the Power Macintosh. It also contains specific optimizations and special features for PowerPC processors. For this reason, it is not exactly the same as Firefox. However, it is intended to be as compatible with it as possible, including most add-ons and [most standard features](TechnicalDifferences.md). You can treat 10.4Fx 24 as equivalent with Firefox 24 in most circumstances, with specific exceptions noted below.

Note that add-ons which require an Intel Macintosh will not work with TenFourFox, even if they are otherwise compatible with Firefox 24, and add-ons that require 10.5 Leopard may not be compatible with TenFourFox running on Mac OS X 10.4 Tiger, even if they are compatible with PowerPC.

## This branch of TenFourFox is the stable version ##

Starting with Firefox 10, Mozilla began offering an extended support release version of Firefox ("Firefox **ESR**") intended for environments where users are unable to use rapid-release versions of Firefox due to policy or technical constraints. This ESR is the basis of the TenFourFox **stable** branch.

The current ESR release is based on Firefox 24. 10.4Fx 24.x is based on this extended support release and is intended for users who wish to remain with a stable browser core. The stable branch will continue to receive bugfixes and security updates, but will not receive new Firefox features (although it may receive certain 10.4Fx-specific features judged important for our legacy users).

**We recommend this version for most of our users.** If you wish to help test our continuing porting efforts, you can try the _unstable_ branch, which is based on the current release of Firefox. _The unstable branch does have bugs and is recommended only for advanced users._ For more information, see the [TenFourFox Development](http://tenfourfox.blogspot.com/) blog.

## TenFourFox no longer supports plugins or Flash ##

Plugins on PowerPC are of special concern because Mozilla is making updates to their plugin architecture which may require the plugins themselves to be updated, and there are certain difficult-to-correct bugs with them already on Tiger. Most importantly, QuickTime, Java and Adobe Flash for PowerPC are no longer maintained and have known security risks that can crash, perform malicious operations or leak data, and Flash 10.1 is rapidly becoming unsupported by many applications.

**For these and other reasons (for details, see PluginsNoLongerSupported), TenFourFox does not run plugins and they cannot be enabled.** Bug reports will no longer be accepted. Sites will now act as if no plugins were installed at all. Earlier versions that allowed an undocumented plugin support mode are no longer supported.

For Internet video, we now recommend the use of TenFourFox's optional QuickTimeEnabler. This allows many videos to be handled in QuickTime Player directly.

You can also download videos for separate viewing using [Perian](http://www.perian.org/) and any of the available video download add-ons for Firefox.

For YouTube, you may also be able to use [MacTubes](http://macapps.sakura.ne.jp/mactubes/index_en.html).  If you have a high end G4 or G5, you can also use WebM for selected videos by visiting http://www.youtube.com/html5 and enabling HTML5 video. This will set a temporary cookie enabling browser-based video without Flash. You do not need a YouTube account for this feature, but you may need to periodically renew the cookie setting. Not all video is available in WebM.

For a more in-depth explanation of this policy and other workarounds, see PluginsNoLongerSupported.

## Fixed in this version of TenFourFox ##

  * All security and stability fixes from Firefox ESR 24.5.0.
  * An issue where the font blacklist could crash the browser has been repaired ([issue 265](https://code.google.com/p/tenfourfox/issues/detail?id=265)).

## Known issues specific to TenFourFox ##

  * Remember: **Plugins do not work in TenFourFox and can no longer be enabled.** See PluginsNoLongerSupported for an explanation and suggested workarounds. Please note that out-of-process plugins have never been supported.
  * TenFourFox uses a lighter chrome for windows and dialogue boxes than prior versions or the official Mac Firefox. This is intentional.
  * Systems with large numbers of fonts installed may experience intermittent pauses.
  * Some pages may perform better on 10.5 systems than 10.4 ([issue 193](https://code.google.com/p/tenfourfox/issues/detail?id=193)).
  * The performance characteristics for the JavaScript compiler used in 24.0 and up are different from those of 17.0.
  * Bitmap-only fonts (usually Type 1 PostScript) cannot be used by the 10.4Fx font renderer and are discarded. A fallback font will be used in their place.
  * Personas and certain custom skins may hide the "traffic light" window buttons, but they are still present and will work if hovered over or clicked on ([issue 247](https://code.google.com/p/tenfourfox/issues/detail?id=247)).
  * Not all webcams are supported; in addition, multiple webcams may not all appear depending on how they are connected ([issue 221](https://code.google.com/p/tenfourfox/issues/detail?id=221)). For a list of supported webcam devices, see VideoDeviceSupport.
  * 10.4Fx does not currently support WebGL, WebRTC or the webapp runtime, and scripts such as Arabic or Indic requiring glyph reordering or language-specific ligatures may not appear correctly. See TechnicalDifferences for the complete list of changes necessary for 10.4Fx. See [issue 5](https://code.google.com/p/tenfourfox/issues/detail?id=5) for notes specific to the font issue.
  * The titlebar does not always properly match the menu gradient ([issue 16](https://code.google.com/p/tenfourfox/issues/detail?id=16)). This problem is also in the official release. Installing a Persona may fix this issue if you find it bothersome.
  * Crash reporting is intentionally disabled to avoid polluting Mozilla's crash tracking system with our reports. Please use your system's crash logs if you are reporting a _reproducible_ crash, or (if you are able) provide a `gdb` backtrace.
  * Although 10.4Fx will tell you when an update is available, you must download updates manually at this time.

You are welcome to report other bugs that you find. However, please **do not report Mozilla bugs to us.** If the bug or crash occurs in both the official Mozilla Firefox 24 _(3.6 doesn't count!)_ and in 10.4Fx, this is a Mozilla bug, and you should file it at [Bugzilla](http://bugzilla.mozilla.org/). **You must test your bug in both places -- bugs that are not confirmed to be part of 10.4Fx will be marked invalid** so that we can keep our task list focused. This is the [current list of known issues](http://code.google.com/p/tenfourfox/issues/list).