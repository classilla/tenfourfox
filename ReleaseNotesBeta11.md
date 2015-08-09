**Beta 10 was skipped due to the rapid back-to-back release schedule.**

_This document may be updated for late-breaking changes, so check back here if you are having difficulty._

## System requirements ##

TenFourFox (hereafter "10.4Fx") requires a G3 Power Macintosh, Mac OS X 10.4.11, 100MB of free disk space and 256MB of RAM. 512MB of RAM and a G4 or G5 processor is recommended. Video playback is likely to be suboptimal on systems slower than 1.25GHz. Mac OS X 10.5.8 is supported.

Intel Macintoshes are not supported, but the G3 build is known to run under Rosetta in 10.5.8. It is not tested with Snow Leopard.

## Getting 10.4Fx ##

Make sure you select the appropriate build for your Mac from the [download page](http://www.tenfourfox.com/). The G3 version will run on any supported Macintosh, but it will not take advantage of the additional features of G4 or G5 processors. The G4 and G5 versions will not run correctly on a G3, and the G5 version will perform worse on non-G5 Macintoshes.

If you are using a G4, you should try to choose the correct version for your processor generation (7400 or 7450 "G4e") as performance may be impaired if you run the wrong one. If you don't know which G4 processor you have, the instructions in WhichVersion will tell you how to find out.

## Beta considerations ##

**This version of TenFourFox is a beta.** It is only _mostly_ complete. In particular, there are some late breaking features planned for the final version which are not yet present in this beta (which is equivalent to Mozilla Firefox 4.0 beta 11), and there will be some final additional optimizations specific to 10.4Fx which will be made just prior to final release. **You should know that you are using this software at your own risk. It may cause data loss, security breaches, system instability and crashes. If you are not comfortable with these (remote but possible) possibilities, do not use this beta release.**

## Known issues fixed in this 10.4Fx beta ##

  * All known Mozilla general fixes for 4.0 beta 11.
  * The PowerPC JavaScript nanojit is now enabled for content/web pages ([issue 20](https://code.google.com/p/tenfourfox/issues/detail?id=20)). This dramatically improves page speed and JavaScript support. Browser "chrome" nanojit support will be enabled once stability is assured. The nanojit is most effective on G4 and G3 processors; G5 tuning is in progress ([issue 23](https://code.google.com/p/tenfourfox/issues/detail?id=23)). Currently TenFourFox is the only browser using this code, but it has been submitted back to Mozilla as [bug 624164](https://code.google.com/p/tenfourfox/issues/detail?id=24164). **If you experience difficulty using the nanojit or encounter unexpected JavaScript behaviour,** you can try turning acceleration off by going to `about:config` and toggling `javascript.options.tracejit.content` to `false`. You may wish to restart the browser afterwards, although this is not required.
  * Further improvements to the title bar ([issue 16](https://code.google.com/p/tenfourfox/issues/detail?id=16)).
  * Stub for Gopher protocol support ([issue 3](https://code.google.com/p/tenfourfox/issues/detail?id=3)), which was removed in Firefox 4/Gecko 2.
  * Additional window event and focus management ([issue 19](https://code.google.com/p/tenfourfox/issues/detail?id=19)).

## Known issues specific to 10.4Fx ##

  * Plugins are officially deprecated as of beta 11. This is due to security, performance and technical issues from plugins such as Flash and QuickTime which will soon be no longer updated for Power Macintoshes. These plugins represent a future potential means of compromising browser security, and they use older OS APIs that Mozilla will no longer support. While they will still be supported and will continue to function throughout TenFourFox 4.0, they will be turned off by default in the next major release "4.1," and support for them will be removed entirely in a subsequent version. For more about this, [see this blog entry](http://tenfourfox.blogspot.com/2011/01/plugins-unplugged.html) and [issue 24](https://code.google.com/p/tenfourfox/issues/detail?id=24).
  * 10.4Fx does not currently support WebGL or out-of-process plugins, and Indic, Arabic and other scripts requiring glyph reordering or language-specific ligatures may not appear correctly. See TechnicalDifferences for the complete list of changes necessary for 10.4Fx. See [issue 5](https://code.google.com/p/tenfourfox/issues/detail?id=5) for notes specific to the font issue.
  * Animation performance is currently poorer in Mozilla 2.0/Firefox 4.0 versions using software rendering, which includes 10.4Fx. Mozilla acknowledges this bug, but there is not yet an ETR. See [issue 7](https://code.google.com/p/tenfourfox/issues/detail?id=7).
  * The titlebar does not always properly match the menu gradient ([issue 16](https://code.google.com/p/tenfourfox/issues/detail?id=16)). This problem is also in the official beta, but has a different cause. Installing a Persona may fix this issue if you find it bothersome.
  * Crash reporting is intentionally disabled to avoid polluting Mozilla's crash tracking system with our reports. Please use your system's crash logs if you are reporting a _reproducible_ crash, or (if you are able) provide a `gdb` backtrace.

You may also wish to read the [Mozilla Firefox beta release notes](http://www.mozilla.com/en-US/firefox/4.0b11/whatsnew/) for what's new in this version of Firefox. This page may not yet be available.

You are welcome to report other bugs that you find. However, please **do not report Mozilla bugs to us.** If the bug or crash occurs in both the official Mozilla Firefox and in 10.4Fx, this is a Mozilla bug, and you should file it at [Bugzilla](http://bugzilla.mozilla.org/). **You must test your bug in both places -- during the beta period, bugs that are not confirmed to be part of 10.4Fx will be marked invalid** so that we can keep our task list focused. This is the [current list of known issues](http://code.google.com/p/tenfourfox/issues/list).