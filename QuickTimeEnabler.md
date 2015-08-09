_This wiki page is updated for releases of the QuickTime Enabler. Please check back on this page for the most up-to-date information._

**Please do not post URLs that don't work unless requested. In general, doing so doesn't help us, as the offending URL usually falls under one of the categories that the QTE cannot assist. These comments may be deleted for space.**

# Using the TenFourFox QuickTime Enabler #

The TenFourFox QuickTime Enabler (hereafter the **QTE**) allows you to play selected HTML5 video and audio files and YouTube videos in QuickTime, outside of the browser. You can even play H.264 content with the QTE. This gives you a safer alternative to Flash for many videos.

If you especially need YouTube support, you may also benefit from installing the MacTubesEnabler.

For security considerations with QuickTime 7, see [this blog post](http://tenfourfox.blogspot.com/2012/05/security-blanket-blues.html).

The QTE _does not_ play Flash applets, and is not a substitute for Flash. Sites that only allow video playback through Flash are not compatible with the QTE.

**The QTE is currently a beta release. It works for many media files, but you may experience minor bugs.**

## Installing the QTE ##

The QTE is an **optional add-on** for 10.4Fx. It is not part of the browser by default; you must download it separately. The most recent version is always available from this page. **The QTE requires at least TenFourFox 10.0.0 and QuickTime 7. You cannot use the QTE with any previous version of TenFourFox, and the QTE may not work properly with QuickTime X if you are using an Intel system.**

Once downloaded, drop it on the TenFourFox window, approve the installation and follow the prompts. You do not need to restart the browser; the add-on takes effect immediately.

### Additional codecs required ###

The video formats you can play are significantly increased by installing [Perian](http://www.perian.org/) for QuickTime and it is strongly recommended. Follow the installation directions.

For Tiger users, some H.264 videos may require additional H.264 profile codec support, which the [avc1Decoder package](http://www003.upp.so-net.ne.jp/mycometg3/) offers. Install the component in `/Library/QuickTime` and, optionally, install the preference pane.

Restart QuickTime Player after installing any new components. However, you should not need to restart your Macintosh.

## Using the QTE ##

When you open a video with the QTE, QuickTime Player will automatically start and the video will open _outside_ of the browser. You can have as many videos open as you like. For best results, make sure _Automatically play movies when opened_ is checked in Preferences in the QuickTime Player. Once the video has sufficiently buffered, it will automatically begin to play.

### To play YouTube videos ###

**If you are on a page at `youtube.com`,** simply right-click anywhere on the page. A context menu will appear with a list of resolutions. Click on the desired resolution; if it is available, it will be loaded, and if it is not the QTE will select a fallback resolution. Even if the video states it is "unavailable," you may still be able to access the video with the QTE.

The QTE will tell you the source URL, and then the video will load in QuickTime Player.

If you are using a G5 or dual-processor G4 at or above 1.25GHz, you can probably play most 720p high definition videos. Only G5s at or above 2.5GHz can play 1080p video satisfactorily, and for best results you should set Performance to Fastest in System Preferences. Slower dual-processor G4, single-processor G4 and G3 systems should use standard 480p definition only.

If you are using HTML5 WebM video, you may need to stop the video from playing in the browser or close the video tab entirely before opening it in the QTE.

**If you are trying to play an embedded YouTube video,** you may be able to SHIFT-right-click (hold down SHIFT and right-click) on the video to play it, but this will not work if the site has only embedded the Flash video stream. If the site has a link to the actual YouTube video page, this will be more reliable.

**For particularly problematic YouTube videos, the MacTubesEnabler may help.**

If you have QuickTime Pro, you can then save the video to disk to play later.

### To play generic HTML5 video and audio ###

Sites that use the `<video>` and `<audio>` tags can play directly in the QTE. Simply right-click on the video or audio and select `Open Media in QuickTime`. The QTE will tell you the source URL, and then the media will open in QuickTime Player.

On some sites, you may need to click the video to start it playing before the browser will let you select the Open Media option.

If you have QuickTime Pro, you can then save the media file to disk to play later.

### To play _links to_ video and audio ###

If you are on a page where you have a link to an audio or video file, you can right click on the link and select `Open Link in QuickTime`. The QTE will then get the target of the link and try to play it in QuickTime Player.

There is no way the QTE can know what's on the other end, however, so use it only on links you reasonably believe are playable media files. JavaScript links and buttons, for example, don't work with this.

If you have QuickTime Pro, you can then save the media file to disk to play later.

### To load images into QuickTime Player ###

The QTE can also load images into QuickTime Player. The image does not have to be animated. Simply right-click on the image and select `Open Media in QuickTime`. The QTE will tell you the source URL, and then the image will open in QuickTime Player.

If you have QuickTime Pro, you can then save the image to disk to view later.

## Sites that do not work with the QTE ##

Sites that only offer video through Flash _**will not work**_ (example: CNN, Fox News), unless they offer an HTML5 option.

Sites that require a username and password _**will not work**_ (example: Vimeo).

YouTube videos that require displaying advertisements _**will not work**_. These might work in the MacTubesEnabler, however, depending on the format.

For these sites, one of the Firefox video downloader add-ons may allow you to still retrieve and view these videos outside of the browser.

## Download the QTE ##

**For 24.x and 31.x:** [The most current version is v.120, downloadable here.](http://sourceforge.net/projects/tenfourfox/files/addons/qte/qte-v120.xpi/download)

### Older versions ###

You should only use these for old versions of TenFourFox.

**For 17.x:** [The most current version is v.116, downloadable here.](http://tenfourfox.googlecode.com/files/tenfourfox-quicktime-enabler-116.xpi)

**For 10.x:** [The most current version is v.115, downloadable here.](http://tenfourfox.googlecode.com/files/tenfourfox-quicktime-enabler-115.xpi)

## Changelog ##

v.120. 24 only. Fixes jetpack version. Minor bug fixes.

v.116. 17 only. Fixes jetpack version.

v.115. Fixes YouTube playback; adds play-from-link support. Last version to support TenFourFox 10.

v.114. Converted to beta.