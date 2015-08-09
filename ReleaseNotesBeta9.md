_This document may be updated for late-breaking changes, so check back here if you are having difficulty._

## System requirements ##

TenFourFox (hereafter "10.4Fx") requires a G3 Power Macintosh, Mac OS X 10.4.11, 100MB of free disk space and 256MB of RAM. 512MB of RAM and a G4 or G5 processor is recommended. Video playback is likely to be suboptimal on systems slower than 1.25GHz. Mac OS X 10.5.8 is supported.

Intel Macintoshes are not supported, but the G3 build is known to run under Rosetta in 10.5.8. It is not tested with Snow Leopard.

## Getting 10.4Fx ##

Make sure you select the appropriate build for your Mac from the [download page](http://www.tenfourfox.com/). The G3 version will run on any supported Macintosh, but it will not take advantage of the additional features of G4 or G5 processors. The G4 and G5 versions will not run correctly on a G3.

If you are using a G4, you should try to choose the correct version for your processor generation (7400 or 7450 "G4e") as performance may be impaired if you run the wrong one. If you don't know which G4 processor you have, the instructions in WhichVersion will tell you how to find out.

## Beta considerations ##

**This version of TenFourFox is a beta.** It is only _mostly_ complete. In particular, there are some late breaking features planned for the final version which are not yet present in this beta (which is equivalent to Mozilla Firefox 4.0 beta 9), and there will be some final additional optimizations specific to 10.4Fx which will be made just prior to final release. **You should know that you are using this software at your own risk. It may cause data loss, security breaches, system instability and crashes. If you are not comfortable with these (remote but possible) possibilities, do not use this beta release.**

## Known issues fixed in this 10.4Fx beta ##

  * All known Mozilla general fixes for 4.0 beta 9.
  * The first draft of the PowerPC-specific nanojit is now available, helping to accelerate certain JavaScript operations ([issue 15](https://code.google.com/p/tenfourfox/issues/detail?id=15)). This portion of code is specific to TenFourFox and is still under development, so it is not enabled by default. If you wish to try it on your system and report back to us, you can enable it by setting either or both of `javascript.options.tracejit.chrome` (for browser and browser add-on JavaScript) and `javascript.options.tracejit.content` (for webpages) in `about:config` to `true`. You should probably start with content, and later add chrome once you have ensured they function. Restart your browser after changing these options to make sure they take effect. If you are unable to start the browser after setting these options, you may need to reverse them using beta 8. It is possible that this may affect your installed add-ons.
  * The title bar is now using different code that flickers less ([issue 16](https://code.google.com/p/tenfourfox/issues/detail?id=16)). Because of this, the title bar appears slightly different on Tiger. Personas are unaffected.
  * Additional branding work ([issue 17](https://code.google.com/p/tenfourfox/issues/detail?id=17)).
  * Fixed an issue where clicking in an inactive window did not always bring the application to the front ([issue 19](https://code.google.com/p/tenfourfox/issues/detail?id=19)).

## Known issues in this beta ##

  * Certain sites such as New Twitter have portions of the page that fail to render. This is a Mozilla issue and is also in Firefox beta 9. See Mozilla [bug 623852](https://code.google.com/p/tenfourfox/issues/detail?id=23852).

## Known issues specific to 10.4Fx ##

  * 10.4Fx does not currently support WebGL or out-of-process plugins, and Indic, Arabic and other scripts requiring glyph reordering or language-specific ligatures may not appear correctly. See TechnicalDifferences for the complete list of changes necessary for 10.4Fx. See [issue 5](https://code.google.com/p/tenfourfox/issues/detail?id=5) for notes specific to the font issue.
  * Animation performance is currently poorer in Mozilla 2.0/Firefox 4.0 versions using software rendering, which includes 10.4Fx. Mozilla acknowledges this bug and plans to fix it before final release. See [issue 7](https://code.google.com/p/tenfourfox/issues/detail?id=7).
  * The titlebar does not always properly match the menu gradient ([issue 16](https://code.google.com/p/tenfourfox/issues/detail?id=16)). This problem is also in the official beta, but has a different cause. Installing a Persona may fix this issue if you find it bothersome.
  * Crash reporting is intentionally disabled to avoid polluting Mozilla's crash tracking system with our reports. Please use your system's crash logs if you are reporting a _reproducible_ crash, or (if you are able) provide a `gdb` backtrace.

You may also wish to read the [Mozilla Firefox beta release notes](http://www.mozilla.com/en-US/firefox/4.0b9/whatsnew/) for what's new in this version of Firefox. This page may not yet be available.

You are welcome to report other bugs that you find. However, please **do not report Mozilla bugs to us.** If the bug or crash occurs in both the official Mozilla Firefox and in 10.4Fx, this is a Mozilla bug, and you should file it at [Bugzilla](http://bugzilla.mozilla.org/). **You must test your bug in both places -- during the beta period, bugs that are not confirmed to be part of 10.4Fx will be marked invalid** so that we can keep our task list focused. This is the [current list of known issues](http://code.google.com/p/tenfourfox/issues/list).