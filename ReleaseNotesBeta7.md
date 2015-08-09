_This document may be updated for late-breaking changes, so check back here if you are having difficulty._

## System requirements ##

TenFourFox (hereafter "10.4Fx") requires a G3 Power Macintosh, Mac OS X 10.4.11, 100MB of free disk space and 256MB of RAM. 512MB of RAM and a G4 or G5 processor is recommended. Video playback is likely to be suboptimal on systems slower than 1.25GHz. Mac OS X 10.5.8 is supported.

Intel Macintoshes are not supported, but the G3 build is known to run under Rosetta in 10.5.8. It is not tested with Snow Leopard.

## Getting 10.4Fx ##

Make sure you select the appropriate build for your Mac from the [download page](http://www.tenfourfox.com/). The G3 version will run on any supported Macintosh, but it will not take advantage of the additional features of G4 or G5 processors. The G4/G5 version will not run correctly on a G3.

## Beta considerations ##

**This version of TenFourFox is a beta.** It is only _mostly_ complete. In particular, there are some late breaking features planned for the final version which are not yet present in this beta (which is equivalent to Mozilla Firefox 4.0 beta 7), and there will be some final additional optimizations specific to 10.4Fx which will be made just prior to final release. **You should know that you are using this software at your own risk. It may cause data loss, security breaches, system instability and crashes. If you are not comfortable with these (remote but possible) possibilities, do not use this beta release.**

The beta is based on the nightly build after the beta 7 code freeze. For this reason, the application will appear as "Minefield," which is the Mozilla codename for a nightly build. However, the code is substantially the same. It will appear in your Dock as TenFourFox.

## Known issues specific to 10.4Fx ##

  * 10.4Fx does not currently support WebGL or out-of-process plugins, and Indic, Arabic and other scripts requiring glyph reordering or ligatures may not appear correctly. See TechnicalDifferences for the complete list of changes necessary for 10.4Fx. See [issue 5](https://code.google.com/p/tenfourfox/issues/detail?id=5) for notes specific to the font issue.
  * Self-updates are not yet supported ([issue 4](https://code.google.com/p/tenfourfox/issues/detail?id=4)).
  * Repeatedly trying to open the click-hold menu on the back and forward buttons may cause 10.4Fx to crash ([issue 9](https://code.google.com/p/tenfourfox/issues/detail?id=9)). Right-clicking them for the menu is safe. This will be fixed in the next beta.
  * Crash reporting is intentionally disabled to avoid polluting Mozilla's crash tracking system with our reports. Please use your system's crash logs if you are reporting a _reproducible_ crash, or (if you are able) provide a `gdb` backtrace.

You may also wish to read the [Mozilla Firefox beta release notes](http://www.mozilla.com/en-US/firefox/4.0b7/whatsnew/).

You are welcome to report other bugs that you find. However, please **do not report Mozilla bugs to us.** If the bug or crash occurs in both the official Mozilla Firefox and in 10.4Fx, this is a Mozilla bug, and you should file it at [Bugzilla](http://bugzilla.mozilla.org/). **You must test your bug in both places -- during the beta period, bugs that are not confirmed to be part of 10.4Fx will be marked invalid** so that we can keep our task list focused. This is the [current list of known issues](http://code.google.com/p/tenfourfox/issues/list).