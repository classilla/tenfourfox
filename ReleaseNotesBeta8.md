_This document may be updated for late-breaking changes, so check back here if you are having difficulty._

## System requirements ##

TenFourFox (hereafter "10.4Fx") requires a G3 Power Macintosh, Mac OS X 10.4.11, 100MB of free disk space and 256MB of RAM. 512MB of RAM and a G4 or G5 processor is recommended. Video playback is likely to be suboptimal on systems slower than 1.25GHz. Mac OS X 10.5.8 is supported.

Intel Macintoshes are not supported, but the G3 build is known to run under Rosetta in 10.5.8. It is not tested with Snow Leopard.

## Getting 10.4Fx ##

Make sure you select the appropriate build for your Mac from the [download page](http://www.tenfourfox.com/). The G3 version will run on any supported Macintosh, but it will not take advantage of the additional features of G4 or G5 processors. The G4 and G5 versions will not run correctly on a G3.

If you are using a G4, you should try to choose the correct version for your processor generation (7400 or 7450 "G4e") as performance may be impaired if you run the wrong one. If you don't know which G4 processor you have, the instructions in WhichVersion will tell you how to find out.

## Beta considerations ##

**This version of TenFourFox is a beta.** It is only _mostly_ complete. In particular, there are some late breaking features planned for the final version which are not yet present in this beta (which is equivalent to Mozilla Firefox 4.0 beta 8), and there will be some final additional optimizations specific to 10.4Fx which will be made just prior to final release. **You should know that you are using this software at your own risk. It may cause data loss, security breaches, system instability and crashes. If you are not comfortable with these (remote but possible) possibilities, do not use this beta release.**

## Known issues fixed in this 10.4Fx beta ##
  * New TenFourFox-specific branding.
  * Enabled support for ligatures and font features ([issue 5](https://code.google.com/p/tenfourfox/issues/detail?id=5)).
  * Separate builds for early G4 systems, i.e., 7400/7410 CPUs, and G5 systems ([issue 10](https://code.google.com/p/tenfourfox/issues/detail?id=10)).
  * Manual updates and automatic notification are now supported ([issue 4](https://code.google.com/p/tenfourfox/issues/detail?id=4)).
  * Repeatedly click-hold-opening the menu on the back and forward buttons no longer causes 10.4Fx to crash ([issue 9](https://code.google.com/p/tenfourfox/issues/detail?id=9)).
  * Black bars over certain web page elements should no longer appear ([issue 2](https://code.google.com/p/tenfourfox/issues/detail?id=2)).
  * Fixes to keyboard settings in plugins ([issue 12](https://code.google.com/p/tenfourfox/issues/detail?id=12)).

## Known issues specific to 10.4Fx ##

  * 10.4Fx does not currently support WebGL or out-of-process plugins, and Indic, Arabic and other scripts requiring glyph reordering or language-specific ligatures may not appear correctly. See TechnicalDifferences for the complete list of changes necessary for 10.4Fx. See [issue 5](https://code.google.com/p/tenfourfox/issues/detail?id=5) for notes specific to the font issue.
  * Animation performance is currently poorer in Mozilla 2.0/Firefox 4.0 versions using software rendering, which includes 10.4Fx. Mozilla acknowledges this bug and plans to fix it before final release. See [issue 7](https://code.google.com/p/tenfourfox/issues/detail?id=7).
  * Crash reporting is intentionally disabled to avoid polluting Mozilla's crash tracking system with our reports. Please use your system's crash logs if you are reporting a _reproducible_ crash, or (if you are able) provide a `gdb` backtrace.

You may also wish to read the [Mozilla Firefox beta release notes](http://www.mozilla.com/en-US/firefox/4.0b8/whatsnew/) for what's new in this version of Firefox. (This page will be available after 21 December 2010.)

You are welcome to report other bugs that you find. However, please **do not report Mozilla bugs to us.** If the bug or crash occurs in both the official Mozilla Firefox and in 10.4Fx, this is a Mozilla bug, and you should file it at [Bugzilla](http://bugzilla.mozilla.org/). **You must test your bug in both places -- during the beta period, bugs that are not confirmed to be part of 10.4Fx will be marked invalid** so that we can keep our task list focused. This is the [current list of known issues](http://code.google.com/p/tenfourfox/issues/list).