_This document may be updated for late-breaking changes, so check back here if you are having difficulty._

## System requirements ##

TenFourFox (hereafter "10.4Fx") requires a G3 Power Macintosh, Mac OS X 10.4.11, 100MB of free disk space and 256MB of RAM. 512MB of RAM and a G4 or G5 processor is recommended. Video playback is likely to be poor on systems slower than 1.25GHz; a G5 is recommended. Mac OS X 10.5.8 is supported.

Intel Macintoshes are not supported, but the G3 build is known to run under Rosetta in 10.5.8 and should run under Rosetta in Intel 10.4.11. It is not tested with Snow Leopard. 10.4Fx will not run under Lion, as Lion does not support Rosetta and 10.4Fx is not a Universal binary.

## Getting TenFourFox ##

Make sure you select the appropriate build for your Mac from the [download page](http://www.tenfourfox.com/). The G3 version will run on any supported Macintosh, but it will not take advantage of the additional features of G4 or G5 processors. The G4 and G5 versions will not run correctly on a G3, and the G5 version will perform worse on non-G5 Macintoshes.

If you are using a G4, you should try to choose the correct version for your processor generation (7400 or 7450 "G4e") as performance may be impaired if you run the wrong one. If you don't know which G4 processor you have, the instructions in WhichVersion will tell you how to find out.

## TenFourFox 4.0.3 is the final release of TenFourFox 4 ##

TenFourFox uses modified Firefox source code, rewritten to remain compatible with Mac OS X v10.4 and the Power Macintosh. It also contains specific optimizations and special features for PowerPC processors. For this reason, it is not exactly the same as Firefox. However, it is intended to be as compatible with it as possible, including most add-ons and [most standard features](TechnicalDifferences.md). You can treat 10.4Fx as equivalent with Firefox 4.0.1 in most circumstances, with specific exceptions noted below.

Please note that Mozilla has not released a Firefox 4.0.3; this is a special TenFourFox release. This version of TenFourFox is a security, stability and performance update addressing known Mozilla security issues and 10.4Fx-specific bugs. **This release is intended for users who require TenFourFox 4.0.x and cannot use TenFourFox 5. There will be no further updates to TenFourFox 4.**

Note that add-ons and plugins which require an Intel Macintosh will not work with TenFourFox, even if they are otherwise compatible with Firefox 4, and add-ons and plugins that require 10.5 Leopard may not be compatible with TenFourFox running on Mac OS X 10.4 Tiger, even if they are compatible with PowerPC.

## Known issues fixed in this version of TenFourFox ##

  * A crash bug in the JavaScript interpreter has been repaired ([issue 63](https://code.google.com/p/tenfourfox/issues/detail?id=63)). This fix is also in 10.4Fx 5.0.
  * Multiple applicable Mozilla-general security and stability issues have been applied and/or backported.

## Known issues specific to TenFourFox ##

  * **Plugins, although most will still work, are _officially deprecated._** This is due to security, performance and technical issues from plugins such as Flash and QuickTime which will soon be no longer updated for Power Macintoshes. These plugins represent a future potential means of compromising browser security, and they use older OS APIs that Mozilla will no longer support. While they will still continue to function throughout TenFourFox 4.x, only major bugs will be repaired, and it is possible there may be graphical glitches. **Plugins will be turned off by default in TenFourFox 6, and support for them will be removed entirely in a subsequent version.** For more about this, [see this blog entry](http://tenfourfox.blogspot.com/2011/01/plugins-unplugged.html) and [issue 24](https://code.google.com/p/tenfourfox/issues/detail?id=24).
  * When 10.4Fx has no suggestions for the awesome bar, a blank box appears instead ([issue 21](https://code.google.com/p/tenfourfox/issues/detail?id=21)). This is intentional.
  * 10.4Fx does not currently support WebGL or out-of-process plugins, and Indic, Arabic and other scripts requiring glyph reordering or language-specific ligatures may not appear correctly. See TechnicalDifferences for the complete list of changes necessary for 10.4Fx. See [issue 5](https://code.google.com/p/tenfourfox/issues/detail?id=5) for notes specific to the font issue.
  * Animation performance is currently poorer in Mozilla 2.0/Firefox 4.0 versions using software rendering, which includes 10.4Fx. Mozilla acknowledges this bug, but there is not yet an ETR. See [issue 7](https://code.google.com/p/tenfourfox/issues/detail?id=7).
  * The titlebar does not always properly match the menu gradient ([issue 16](https://code.google.com/p/tenfourfox/issues/detail?id=16)). This problem is also in the official release. Installing a Persona may fix this issue if you find it bothersome.
  * Crash reporting is intentionally disabled to avoid polluting Mozilla's crash tracking system with our reports.
  * Although 10.4Fx will tell you when an update is available, you must download updates manually at this time.

No further bug reports are being accepted against this version of TenFourFox. If you experience what you believe to be a bug, we recommend updating to TenFourFox 5 or higher. This is the [current list of known issues](http://code.google.com/p/tenfourfox/issues/list).