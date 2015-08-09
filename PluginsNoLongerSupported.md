**To keep this page useful and non-cluttered, comments that are not related to plugin alternatives may be deleted for space. Please do not modify this document unless you are authorized to do so.**

# Why aren't plugins supported in TenFourFox? Why can't I use Flash? #

One of the controversial decisions made in TenFourFox (henceforth _10.4Fx_) 6.0 was to disable plugin support, which includes Flash, QuickTime, PDF plugins and other specific kinds of functionality. This page is to explain why and to give you safer options.

## Plugins (unsupported) versus add-ons (mostly supported) ##

A _plugin_ is a system module of native code, which the browser runs when trying to handle a specific type of content it doesn't handle usually, such as QuickTime movies, PDF documents or Flash video or Flash applets. Plugins are generally system-wide: the same plugin you used previously in 10.4Fx is the same plugin you use in Safari or Camino. Plugins do not alter the browser itself, although they can affect the browser, and they run within a specific window or tab instance only when called for. TenFourFox no longer supports plugins.

An _add-on_ is a browser module, usually written in JavaScript and XUL. It only works in Firefox and 10.4Fx, and can be used for a wide variety of browser features such as adding protocol support, blocking content (such as scripts and advertisements) or adding new functionality. Some features are only possible with add-ons, and add-ons can significantly modify the browser as a whole rather than being limited to a specific window or tab. Because of their privileged nature, Mozilla curates add-ons that appear on [their official site](http://addons.mozilla.org/) and many authors offer regular updates to fix bugs and security issues.

TenFourFox _does_ support _most_ add-ons. The add-ons it does not support are those that contain native Intel code, or, on Tiger Macs, add-ons that contain native code that requires Leopard. **You can continue to use add-ons compatible with the same version of Firefox in TenFourFox in most cases.**

## PowerPC plugins are unmaintained and insecure, and Mozilla is changing the plugin environment ##

No major plugin is being maintained for Power Macs any more: Flash stopped updates with Flash 10.1.102.64 in November 2010, and QuickTime 7 for the PowerPC was decommissioned with the release of QuickTime 7.7 and OS X Lion in August 2011. (Tiger users have not had an update since QT 7.6.4 in September 2009.)

Plugins have special access to the system. When they are instantiated by the browser, they run as if you were running any regular application, which is true even for out-of-process plugins (which were never available for 10.4Fx due to Tiger SDK limitations). Like any buggy or insecure application, they can be exploited or made to crash, and because the plugin runs within the browser, such methods can also be used to attack, spy upon or destabilize the browser as well. They have also been used to [attack the network the computer is running on](http://www.pcworld.com/article/141399/flash_attack_could_take_over_your_router.html), and a well-crafted attack vector such as that example can run anywhere Flash does, including Power Macs. Because plugins load automatically by default when the page calls for them, your system could be exploited before you even notice.

Many of these attacks can be mitigated, though not entirely prevented, by the use of add-ons that can block plugins from loading. However, there is still another problem apart from security: Mozilla is changing the environment and the technical requirements for how plugins interact with the system. These technical requirements are difficult to achieve with Mac OS X 10.4, and there are known graphical and compatibility bugs already. It is entirely possible that in the near future, extant PPC-compatible plugins will not function properly or at all.

The final nail in the coffin, however, is that even when working properly many sites now require Flash 11 or higher, which will never be available for Power Macs. Even if these two issues didn't apply, it still isn't possible to view some kinds of content, it never will be, and this problem will only get worse.

## Towards a plugin-free future ##

TenFourFox survives on the volunteer work of its maintainers. It is already a large workload to maintain the browser's compatibility with Mac OS X 10.4, 10.5 and PowerPC in general, and in the not-too-distant future Mozilla will not support 10.6 either which will add to the burden.

It doesn't make good use of our resources, then, to try to get legacy code that is not under our control to operate within the moving target that is Mozilla plugin support, especially now that Mozilla has dramatically increased the speed at which they release new versions. And even if we did get them to work, because we don't control the code behind them we continue to risk exposing ourselves and our users to insecure software that will become less and less compatible and more and more vulnerable with time.

With TenFourFox, we're concentrating on optimizing open alternatives that can run within the browser, such as faster JavaScript, faster browser-generated graphics and faster WebM HTML5 video. As Mozilla adds more interactive HTML5 features to Firefox, many of these features will appear in 10.4Fx, superseding the need for plugins.

## What can I use to replace Flash and QuickTime right now? ##

There will still be some content you can't view without a Flash plugin in the browser. Some of it can be worked around.

  * TenFourFox can open some videos in QuickTime Player directly using the QuickTimeEnabler. This is compatible with many HTML5 video and audio files, and YouTube.

  * For YouTube videos in particular, the free [MacTubes](http://macapps.sakura.ne.jp/mactubes/index_en.html) application allows you to view YouTube video in multiple resolutions and full-screen. It is also more efficient at playback on older Macs. Please support this excellent application.
  * If you have a fast-enough G4 or G5, you can also view many YouTube videos using TenFourFox's built-in HTML5 WebM video support, which _is_ supported. To do so, visit http://www.youtube.com/html5 and "opt in" to the HTML5 trial. This will set a temporary cookie so that available embedded videos and videos on YouTube will be presented to you in native HTML5 video, if available. While you do not need a YouTube account to use HTML5 video, the cookie may periodically expire and require renewal, and not all videos are available in WebM.
  * For other video files, you can use any of the available Firefox YouTube or Flash video download extensions, and view the media files off-line with [Perian](http://www.perian.org/) for QuickTime (or QuickTime itself for codecs QT supports).
  * For other audio files, download the audio file and play it in QuickTime Player.
  * For PDF documents, download and view them in Preview or Adobe Reader. Mozilla support for in-browser PDF is under development.

We welcome other plugin-free suggestions in the comments. Thanks for your understanding and helping us work towards preserving the long-term longevity of the Power Mac platform. The more functional code we have under the control of the community, the longer our Macs will be serviceable and useful. This means eliminating proprietary software in favour of open solutions is a must for future maintainability, and dropping plugin support, while painful now, will pay off handsomely later.