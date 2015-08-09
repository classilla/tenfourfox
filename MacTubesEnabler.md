## The MacTubes Enabler is no longer receiving updates because of the end of support for the older YouTube API used by MacTubes. When/if this changes, the Enabler will be updated. Until then, we suggest the QuickTimeEnabler, which does work with many YouTube videos as well. ##

_This wiki page is updated for releases of the MacTubes Enabler. Please check back on this page for the most up-to-date information._

# Using the TenFourFox MacTubes Enabler #

The TenFourFox MacTubes Enabler (hereafter the **MTE**) allows you to play selected  YouTube videos in MacTubes, outside of the browser. This gives you a safer alternative to Flash for many videos and for those YouTube videos that do not perform well with the QuickTimeEnabler (hereafter the **QTE**).

The MTE does not replace the QTE. The QuickTimeEnabler is needed for HTML5 files and other kinds of media content that are outside of YouTube, and the QTE allows you to play certain YouTube videos in QuickTime Player instead of MacTubes if you prefer. **You can have both the QTE and MTE installed at the same time. You do not need the QTE to use the MTE.**

For security considerations with QuickTime 7, see [this blog post](http://tenfourfox.blogspot.com/2012/05/security-blanket-blues.html).

**The MTE is currently a beta release. It works for many YouTube videos, but you may experience minor bugs.**

## Installing the MTE ##

The MTE is an **optional add-on** for 10.4Fx. It is not part of the browser by default; you must download it separately. The most recent version is always available from this page. **The MTE requires at least TenFourFox 24.1.0 and MacTubes 3.1.6. The MTE is not supported on any previous release of 10.4Fx.**

First, install MacTubes from its home page: http://macapps.sakura.ne.jp/mactubes/index_en.html

Make sure MacTubes is able to find and play your typical YouTube videos. If it cannot, the MTE will not help you.

Once you've confirmed MacTubes can play your desired content, download the MTE using the links below. Once downloaded, drop it on the TenFourFox window, approve the installation and follow the prompts. You do not need to restart the browser; the add-on takes effect immediately.

### Additional codecs required ###

The video formats you can play are significantly increased by installing [Perian](http://www.perian.org/) for QuickTime and it is strongly recommended. Follow the installation directions.

For Tiger users, some H.264 videos may require additional H.264 profile codec support, which the [avc1Decoder package](http://www003.upp.so-net.ne.jp/mycometg3/) offers. Install the component in `/Library/QuickTime` and, optionally, install the preference pane.

Restart QuickTime Player after installing any new components. However, you should not need to restart your Macintosh.

## Using the MTE to play YouTube videos ##

**If you are on a page at `youtube.com`,** simply right-click anywhere on the page. A context menu will appear with an option to `Open YouTube Video in MacTubes`. Select that option. The video will automatically open in MacTubes (if MacTubes is not already running, it will automatically start).

**If you are trying to play an embedded YouTube video,** you may be able to right-click on the video itself to play it, but this may not work if the site has only embedded the Flash video stream. If the site has a link to the actual YouTube video page, this will be more reliable.

For optimal playback, especially of unusual codecs or high-definition content, we recommend setting MacTubes to the QuickTime Player option under Preferences, Player. You may need to enable FLV videos under Preferences, Format for some movies to play at all. (FLV support needs Perian for playback.)

If you are using a G5 or dual-processor G4 at or above 1.25GHz, you can probably play most 720p high definition videos. Only G5s at or above 2.5GHz can play 1080p video satisfactorily, and for best results you should set Performance to Fastest in System Preferences. Slower dual-processor G4, single-processor G4 and G3 systems should use standard 480p definition only.

If you are using HTML5 WebM video, you may need to stop the video from playing in the browser before opening it in the MTE. You can also try selecting `Open YouTube Video in MacTubes, Close Tab` which will open the video and automatically close the YouTube tab it came from so that no further downloading, decoding or playback occurs.

## Download the MTE ##

[The most current version is v.1, downloadable here.](http://tenfourfox.googlecode.com/files/mactubes-enabler-beta1.xpi)

## Changelog ##

v.1. Initial release.