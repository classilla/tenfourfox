**Please don't modify this document unless you are authorized to do so. Comments not related or relevant to the most current release of TenFourFox may be deleted for space.**

# TenFourFox Frequently Asked Questions #

This page is for frequently asked questions about TenFourFox (or, as we abbreviate it, 10.4Fx). Some of these are also answered on the main site and other places in Google Code, but are also provided here for convenience.

Questions answered in the FAQ are generally pertinent only to the **most current version of 10.4Fx** although notes about earlier versions are also included for reference.

## What is TenFourFox? ##

TenFourFox (_hereafter 10.4Fx_) is a port of Firefox to the Power Macintosh, running either Mac OS X 10.4 or 10.5.

## Why make 10.4Fx? ##

Mozilla stopped supporting Power Macintosh and Mac OS X v10.4 with Firefox 4/Mozilla 2.0, both of which remain important and in our humble opinion viable platforms, particularly for people who need to run older software or use Classic. We fall into this category. This is our attempt to rectify the disparity.

## Why isn't it called Firefox? ##

10.4Fx is not called Firefox because technically it isn't, and therefore legally it can't be. Mozilla's trademark conditions require that builds named Firefox be based on unmodified source, and 10.4Fx is modified.

## What modifications were made to 10.4Fx? ##

See TechnicalDifferences for the current set. In broad strokes, however, 10.4Fx contains modified widget code to work with OS X Tiger, contains modified font code to remove Mozilla's dependency on CoreText, disables graphics acceleration and WebGL (which are not compatible with Tiger), and includes AltiVec- and PowerPC-specific code such as its own JavaScript JIT accelerator and WebM decoder. There are other smaller changes due to the older build system available to 10.4.

## Does Mozilla support TenFourFox? ##

**No. TenFourFox is not an official Mozilla build or product.** That said, our project lead is a member of the Mozilla security group, and all our contributors routinely upstream patches we believe of benefit to other PowerPC builds of Firefox, which Mozilla accepts. However, we maintain separate support networks, build systems, and distribution infrastructure which Mozilla has no role in operating; no one working on this port is a Mozilla employee; and the project receives no material support from Mozilla. In short, we are no different to Mozilla than any other 3rd-party "Tier 3" port.

## What is the difference between the _stable_ and _unstable_ branches? ##

(This question does not apply to version 9.0 and earlier.)

The _stable_ branch of TenFourFox is based on the Firefox extended support release, otherwise known as the Firefox **ESR**. The ESR receives bugfixes and security updates from Mozilla, but no new Firefox-general features. The _unstable_ branch of TenFourFox is based upon the current version of Firefox.

The _stable_ branch, despite its name, does receive selected new TenFourFox features and does have "betas" for testing them, but does not receive other feature updates from Mozilla. Although it is not as technologically advanced as the _unstable_ branch, it is based on tested and stable code and receives security updates, and therefore **the stable branch is the recommended version for most users.**

Because the _unstable_ branch is not a release-quality version, it frequently has known bugs, and therefore is only recommended for developers and advanced users. Nevertheless, we encourage technically proficient users to help us develop and keep the PowerPC Firefox port viable. If you are interested in helping to test the _unstable_ branch, please visit the [TenFourFox Development](http://tenfourfox.blogspot.com/) blog.

## Are there other PowerPC OS X builds of Firefox? ##

We are no longer aware of other current builders. For a period of time AuroraFox issued a 10.5-only build, but is no longer supported as of Firefox 20. There are also some older Firefox rebuilds for Power Macs made directly from Mozilla's source code, but none of them are still maintained.

However, there is a Tenfourbird based on 10.4Fx code for Thunderbird users, compatible with 10.4 and 10.5, and a version of SeaMonkey for 10.5 only.

We do not officially endorse any alternative build (other than our own, of course), although some of these builders also contribute to this project.

## Why are there four different versions? Which one do I pick? ##

10.4Fx comes in processor-tuned variants to give you the best speed on your particular Macintosh. The G4 and G5 versions include AltiVec code, for example, and the G5 JavaScript accelerator is tuned differently for better performance on the PowerPC 970. If you are using a G3 or a G5, you should use the G3 or G5 version, respectively. If you are using a G4, see WhichVersion for whether you should use the 7400 or 7450 build.

## Can 10.4Fx run on Panther? (Jaguar, etc.?) ##

No. OS X 10.3 does not contain the secret CoreText that is necessary for portions of the underlying font code, and because current versions of Firefox depend strongly on Cocoa, the core operating system libraries in general are not advanced enough to support the browser base. There is no easy way to fix this. For Panther, your best bet is probably Camino 1.6.1; you might also consider SeaMonkey 1.1, which will work for Jaguar too. You could also run [Classilla](http://www.classilla.org/) in Classic, which is also your best option for 10.0-10.1 if anyone is still running that, and of course OS 8.6 and OS 9.

## I started up TenFourFox and it doesn't work/won't start. Don't you even test your software? ##

No, we don't use the browser we write, at all. :P Joking aside, serious crippling issues like this are usually due to something local; failure to even start up would be rapidly apparent to our testing audience. To diagnose the problem will need a little detective work.

The first thing to try when the browser won't work or won't even start is to try to start in safe mode -- hold down the Option key as you start 10.4Fx. This will disable any problematic extensions and themes and certain other browser features. If this fixes the problem, you should attempt to find which extension or feature is the problem. Some older extensions may cause serious issues with the browser.

If this doesn't fix it, you should try [starting with a blank profile](http://tenfourfox.tenderapp.com/kb/general/how-to-reset-your-profile) instead of your earlier Firefox profile. Profiles created by versions of Firefox prior to 3.6 may corrupt or be unreadable to 10.4Fx. **If you upgraded from a very old version of Firefox (such as 2.x, 3.0 or 3.5) directly to TenFourFox, your profile probably won't work. You should try to upgrade to versions inbetween if you want to keep your profile so that information is properly upgraded at each step.** See _Will 10.4Fx use all my Firefox settings?_ below for more information. You may be able to keep the profiles separate if you are unable to do this, though it is not recommended.

If you want to open a support ticket, please include any output from `Console.app` that appears when you start the application (don't cut and paste everything, just what is new).

[Mozilla's Firefox OS X support pages](http://support.mozilla.com/en-US/kb/Firefox%20will%20not%20start) also have other suggestions for fixing startup problems.

Also, see if the suggestions in the next question help you: ...

## 10.4Fx says that it is "not supported on this architecture." ##

There are several causes for this message:

  * You accidentally downloaded Firefox, not TenFourFox. Firefox is an Intel-only application and will not run on a Power Mac.
  * You accidentally downloaded the wrong architecture version. A Power Mac G3 will not run anything but the G3 version; the G4 or G5 versions will either give you this message or not run at all.
  * The tool you used to unzip 10.4Fx corrupted it. **Do not use third-party unzipping tools (such as Zipeg and others) to open the .zip file; it may corrupt the application.** Use the native OS X archive utility that comes with Tiger and Leopard (it is in `/System/Library/CoreServices/BOMArchiveHelper.app`, or you can try right-clicking on the .zip file and selecting it from the `Open With...` list).

## 10.4Fx is very slow when it starts up. ##

Since Firefox 5, Mozilla has required that most of the components of the browser be combined into a large "superlibrary" called _XUL_; it is no longer possible to run with the pieces separated anymore. XUL contains the bulk of the browser's code, roughly 70MB in size in current versions, and when the browser starts up this entire library needs to be scanned and components loaded from it. Part of this process happens on startup, but some happens on demand, so the first few pages you load might be slower than they should be. On a fast G5, this might be only a matter of a few seconds, but obviously it takes longer on computers with slower CPUs or slower hard disks.

There is a silver lining, though: once XUL is mostly/fully loaded, much of it remains in memory, and the browser becomes considerably faster. Plus, because the components are kept all in one place, certain types of glue code can be dispensed with, allowing the browser to have even less overhead once it's fully loaded. As long as you keep the browser open and don't quit it (you can sleep your Mac with 10.4Fx running), you won't have to pay this startup penalty again unless you have to restart the browser.

## Can 10.4Fx run on an Intel Mac with 10.4 or 10.5? ##

Yes, but: **Intel Macintoshes are not supported. Please do not ask for support on Tenderapp.** Because Intel is a better-known architecture to attackers than PowerPC, both Intel 10.4 and 10.5 are much more likely to be successfully attacked than PowerPC, even though both technically have the same or similar security holes. You are strongly advised to update to at least Snow Leopard (10.6) and run the regular Firefox, which will give you security updates and still lets you run most OS X PowerPC applications. Apple still sells Snow Leopard, which even the earliest Intel Macs can run and is a necessary prerequisite for 10.7 through 10.9: http://store.apple.com/us/product/MC573/mac-os-x-106-snow-leopard

That having been said, if you are absolutely unable or unwilling to upgrade your Intel Mac, it is possible to run TenFourFox on it under Rosetta with 10.4-10.6. However, because TenFourFox uses advanced custom code specific to the PowerPC architecture, Rosetta may have compatibility problems running the browser. Follow the steps below:

  * First, make sure you are using the _G3_ version; the others, particularly the G5 version, will not work with Rosetta under _any_ circumstances.

  * Second, if the browser crashes when you try to start it, try to restart it in **safe mode** (hold down the Option key as you start the browser). If this allows the browser to start, you will need to disable the JavaScript compiler permanently. Go to `about:config` by typing it in your address bar. Find all the preferences starting with `javascript.options.baselinejit` and `javascript.options.ion` and make sure they are set to `false` by double-clicking the value. If they are already false, leave them alone. **Do not change any other options.** Restart 10.4Fx and see if this fixes the problem. You can also try this if you experience inexplicable crashes with 10.4Fx on your Intel Mac, even if it appears to start normally.

In general, using Rosetta to run TenFourFox will be noticeably _slower_ on an Intel Mac, even if you are successful in starting it up. The reason is that Rosetta must convert all the PowerPC code in it into Intel machine language on the fly and there is no AltiVec or other acceleration support. As a result, it will appear to be much slower than Firefox 3.6, 10 or 16, all of which have native Intel code. However, it is more up-to-date with security patches and fixes, so you may prefer it if your Intel Mac is sufficiently fast enough.

At one time a TenFourFox 17.0.2 was available for Intel, donated by a contributor, but is no longer being maintained. You should not use this version any more due to known security vulnerabilities. If you can help with building and maintaining a newer release, please post to the development blog.

Finally, let us say it again: **Intel Macintoshes are not supported under any circumstances, period.** Power Macs remain the primary focus of support and development; any indulgence of Intel Macs is on a best-effort basis only. Seriously, please do us all a favour and install Snow Leopard and run the real Firefox.

## Will 10.4Fx use all my Firefox settings? ##

Yes, because as far as your Mac is concerned TenFourFox _is_ Firefox, so it will use your previous profile seamlessly including all of your old bookmarks, all compatible add-ons and all settings. **However, you may wish to install versions in between and upgrade through them** so that your profile is correctly updated, such as from 2 to 3 to 3.6.

Similarly, **if you are updating from a Firefox version prior to 10.0 (such as 3.6), download and install TenFourFox 10.0.11, run it once, then download and install 17.0.11, run that once, then download and install 24.7.0, run that once, then download and install the current version of TenFourFox.** If you are unable to do so, consider removing the `Library/Application Support/Firefox` folder in your home directory to make sure settings are clean and correct, but this will destroy your bookmarks, saved settings, cookies and add-ons. **If your Mac has never run Firefox (even if it ran Camino), you don't need to do this.**

Again, in some cases, you may have corrupted or buggy settings from older versions that will actually cause problems with 10.4Fx. In that case, [you may need to reset your profile](http://tenfourfox.tenderapp.com/kb/general/how-to-reset-your-profile); there is usually no way to fix this otherwise.

As a corollary in general, old versions of Firefox that are no longer supported will typically not be able to use profiles from later versions of Firefox, and may even corrupt them. That brings us to the next question:

## I want to keep my Firefox and 10.4Fx settings separate. ##

If you must use the old Firefox, or use different add-ons or keep different settings, you will need separate profiles. Mozilla explains how to start the Firefox Profile Manager at http://support.mozilla.com/en-US/kb/Managing-profiles. These steps will also work for TenFourFox; just substitute the correct application. **Be careful:** profile management, if done incorrectly, can cause you to lose your current settings and bookmarks. Follow the directions exactly. This is not recommended if you can avoid it.

## I tried to run the Profile Manager like you said, and it gives me a weird error message (on 10.4). ##

Run `firefox -P` instead of `firefox-bin -P`.

In future, once you've created a new profile -- let's say you called it `newprofile` -- you can just type `firefox -p newprofile` to use that profile and avoid using the GUI Profile Manager altogether if you like.

## Can I run 10.4Fx together with Camino, SeaMonkey, Safari or other browsers? ##

Yes. In fact, you can even run them at the same time. Even Gecko-based browsers like Camino and SeaMonkey coexist peacefully with TenFourFox. (We recommend OmniWeb over Safari if you want your WebKit fix, btw.)

Again, the exception is Firefox itself. Firefox 3.6 cannot be run simultaneously with TenFourFox, because as we mentioned above, to the Mac TenFourFox _is_ Firefox. Also, do again remember that older versions of Firefox may cease to work after upgrading to TenFourFox due to incompatible profiles. You may wish to use specific profiles for these older Firefox or even old TenFourFox versions if you must run them (but it is strongly advised you do not, as these versions of Firefox likely have security issues). **We do not support alternating between Firefox 3.6 and TenFourFox, as Firefox 3.6 may not be able to handle the changes in TenFourFox profiles.**

## Does 10.4Fx support Firefox add-ons? ##

Yes, if they are compatible with the same version of Firefox and do not require an Intel Macintosh. For example, **addons such as Adblock Plus, NoScript, Flashblock and OverbiteFF are all compatible.** You can get them by going to Tools, Add-ons.

Remember: **add-ons and plugins are not the same. Add-ons _are_ supported in 10.4Fx.** See PluginsNoLongerSupported for an explanation.

Tiger users should note that even if an extension works with PowerPC, some may require Leopard.

## 1Password does not work with 10.4Fx. ##

Users have asked Agile to support TenFourFox in 1Password and Agile has refused to support _any_ non-Intel build of Firefox after 3.6, including TenFourFox. If you are unhappy about this policy, please tell them so (especially if you are a paid user). In the meantime, if you absolutely require 1Password support, you are stuck with Firefox 3.6. There is no way, unfortunately, to force 1Password to work with TenFourFox from our end.

User Art McGee has suggested that you may be able to use [1Password Anywhere](http://help.agile.ws/1Password3/1passwordanywhere.html) to get around this problem, although this will probably only work for Leopard users. We haven't tested this. Please report your results.

## Gopher sites no longer work in 10.4Fx. ##

You can enable the Gopher protocol with the [OverbiteFF addon](https://addons.mozilla.org/en-US/firefox/addon/overbiteff/).

## Does 10.4Fx support plugins or Flash? ##

**No. Plugins no longer operate in TenFourFox.** 10.4Fx uses older compositing code to remain compatible with OS X Tiger, and the modified graphics stack in Firefox 4 is tuned for CoreAnimation, which Tiger does not support. More to the point, few if any PowerPC-compatible plugins remain updated, and Adobe no longer supports Flash on Power Macintosh.

When you visit a site with plugin content, an informational box may appear on the page where the plugin would normally appear. Sites may also tell you that you have no plugins installed. This is intentional, so that the site can try to present alternate content that does not require a plugin.

Between 6.0 and 17.0.11 an undocumented, unsupported plugin enable setting existed. This option is now completely gone because Mozilla completely removed the older compatibility code. If you turned it on in a previous version of TenFourFox, it will not work in version 19.0 and higher.

See PluginsNoLongerSupported for more information on this policy and ways you can access content without plugins.

## How can I play H.264 video? ##

If a site offers HTML5 H.264 video as an option, you can play many such videos outside of the browser using the optional QuickTimeEnabler. (Please read that wiki page carefully as some sites cannot be supported yet. You may be able to use one of the Firefox video downloader add-ons for those sites; again, see PluginsNoLongerSupported.)

If you are looking for something to play YouTube video specifically, look at the MacTubesEnabler.

## WebM video playback is too slow on my Mac. ##

10.4Fx supports WebM video, which is generally slower than H.264 video because no Power Mac has hardware acceleration for WebM. 10.4Fx does have AltiVec acceleration for WebM, however, which improves performance on G4 and G5 systems. For this reason, most G5 Power Macs can play standard definition WebM without issue but practically no G3 Macs can, due to the CPU power needed to decode, scale and composite the video in the browser.

As for G4 systems in the middle, many will play video with acceptable stuttering, but Macs slower than 1.25GHz are likely to perform badly. If you are in the upper G4 range, video plays back better if you **play the video after it is done downloading** and **reduce the number of tabs open.** Also, because decoded frames can be cached depending on available memory, playing the video a second time often performs considerably better than the first time. Finally, make sure the playback controls are not showing (move your mouse into and back out of the player window if they do not go away on their own), as compositing the controls against the video image uses additional CPU power.

Although 10.4Fx still supports Theora (VP3) video, much less content is available in this format than in WebM, and for this reason its playback is not as well optimized.

Please note that no Power Mac, not even the quad G5, plays high definition WebM fluidly in the browser, nor full-screen WebM. There just isn't enough CPU bandwidth. Similarly, even though recent versions of 10.4Fx support VP9 video, even partial playback is unwatchable on all but the Quad because of the data rate required.

Improving video performance is an active area of development in TenFourFox.

## Does 10.4Fx support Java? ##

**No. Java is specifically disabled by default, and is no longer supported.** Java on 10.4 requires the Java Embedding Plugin, and as mentioned, plugins are no longer supported either. More to the point, neither 10.4 nor 10.5 receive security updates to the JVM any more, and trojans such as Flashback have been able to escalate their privileges even on Power Macs using flaws in these older Java environments. For these reasons Java is no longer supported by TenFourFox, and we strongly recommend you only run signed Java applets from trusted sources on Power Macintoshes.

## 10.4Fx does not display some fonts (Tamil, Arabic, ...) correctly. ##

10.4Fx does not support CoreText, which is needed to use the typographic information in the AAT-encoded fonts that come with OS X. Without this information, certain ligatures and glyph reordering rules cannot be utilized, and the font will appear but not quite correctly. The font renderer in 10.4Fx does support Arabic and other international scripts, but requires OpenType fonts for the special language-specific features. See [issue 5](https://code.google.com/p/tenfourfox/issues/detail?id=5) and TechnicalDifferences.

## On some sites, I keep getting "Unresponsive script" errors. ##

As sites become larger and use more complex JavaScript, even with the special acceleration in 10.4Fx, execution will be slow particularly on G3 and early G4 systems. When script runtime exceeds a certain threshold, this error appears. The error is otherwise harmless and you can continue to wait if you know the operation will complete.

If you get this window frequently, there are a few ways you can improve the browser's script performance. Try some or all:

  * Remove unnecessary browser add-ons. These sometimes will interfere with some sites.
  * Use the [NoScript](https://addons.mozilla.org/en-US/firefox/addon/noscript) add-on and allow JavaScript only to run on certain necessary sites.
  * Disable the unresponsive script warning entirely. Instructions are on [this support ticket](http://tenfourfox.tenderapp.com/discussions/problems/174-unresponsive-script-warning).

## Will 10.4Fx receive updates? ##

Yes. We will update the browser with regular security updates, which your browser will automatically prompt you to download when they become available.

New feature versions of 10.4Fx will also be released until it is no longer possible to compile Mozilla's source code (see SupportLevels). However, even when it is no longer possible, security updates will still occur.

## The browser keeps saying I'm out of date! ##

You will get automatic prompts to update if the browser detects your version is not in sync with the version available. Sometimes this may occur even if you appear to be using the same version (we do not bump the version number between official releases to avoid getting out of sync with Mozilla, but the browser has a different build ID). If you are ever in doubt about the version you have, visit the [TenFourFox Start Page](http://www.tenfourfox.com/start), which will tell you if you are up-to-date.

## Does 10.4Fx support WebM video? ##

Yes. However, video playback generally requires a G5 for best results. See above for suggestions on improving native video playback on G4 systems.

## Does 10.4Fx support WebGL? ##

No. WebGL requires OpenGL 2, which is not supported on Tiger, and Mozilla does not support WebGL on 10.5 either.

## Does 10.4Fx support IonMonkey or BaselineCompiler JavaScript JIT acceleration? ##

TenFourFox uses PPCBC, a specialized PowerPC-specific version of Mozilla BaselineCompiler. BaselineCompiler is a low-latency compiler emphasizing quick code generation.

IonMonkey support is being worked on for a future version of TenFourFox, and will complement PPCBC.

## Does 10.4Fx support language packs? ##

Yes (see the [main page](http://www.tenfourfox.com/) for a list of languages). More are coming soon!

Looking for your own language? 10.4Fx has slightly different strings than Firefox, so regular language packs need modification. Some enterprising users are already working on it. See [issue 42](https://code.google.com/p/tenfourfox/issues/detail?id=42).

## Why do you make me test my bug reports against the current Firefox? I can't run it on my Mac! ##

After Firefox 3.6, Mozilla introduced many large layout and interface changes (most of them in Firefox 4, but many incrementally after that); moreover, the current rapid release strategy Mozilla is using is certain to introduce more bugs and more compatibility changes more and more quickly. Fixing Mozilla bugs is out of our purview and most of this app is still Mozilla's code. To keep us focused on our mission of keeping Firefox compatible with the Power Mac, we need you to make sure your bug does not also occur in regular Firefox. If it does, it's not our bug.

We realize that the whole point of TenFourFox is to run Firefox on systems that Mozilla no longer supports, so comparisons to any Tier 1 platform are accepted, including Windows, Linux and Mac OS X 10.6+. However, unless your bug report is clearly specific to 10.4Fx (and the template will guide you), **if your bug report does not compare behaviour with stock Firefox, it will be marked invalid.** We don't mean to be jerks, but we need to keep our heads above water and not spin our wheels -- or there won't be a TenFourFox in the future.

## This document didn't answer my question. ##

Please open a support ticket on our [TenFourFox Tenderapp](http://tenfourfox.tenderapp.com/) and one of our friendly support volunteers will try to help you.

If you wish to talk directly to the developers, feel free to drop by and comment on our [TenFourFox Development](http://tenfourfox.blogspot.com/) blog.