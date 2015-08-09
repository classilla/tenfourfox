As of TenFourFox 20, you can use your Power Macintosh's camera or QuickTime-compatible video or audio device to upload photos and video (securely, of course! -- you will always be asked). You can see if your device works with our [user media test page](http://www.floodgap.com/software/tenfourfox/gum_test.html) (don't worry, your images and audio are _not_ uploaded).

However, it is not possible to support all devices. In general, most audio devices will work, but video devices that do not export a standard 640x480 video image and are not IIDC or QuickTime compatible will _not_ work. Some IIDC-compatible FireWire cameras may send a non-standard image, for example, despite being otherwise compliant. These will generate a scrambled image in TenFourFox.

Built-in audio (through the line-in/microphone port) is supported on all supported Macintosh models and is always available. USB audio should work, but has not been tested.

It may be possible to get certain USB webcam devices working with the `macam` driver (available separately). While we can't necessarily support these ourselves, we'd like to know if they at least do work. Other USB video sources may not be compatible. Again, if they don't work with QuickTime, they will almost certainly not work with TenFourFox.

Please post working and non-working devices in the comments. We will try to support as many devices as reasonably possible within technical constraints.

## Working and supported ##

iSight FireWire -- both audio and video (using built-in 10.4 IIDC driver)

HP HD-3110 USB -- both audio and video (using built-in 10.4 UVC driver)

Logitech HD Webcam C310 USB -- both audio and video (using built-in 10.4 UVC driver)

## Not working (yet) ##

Rocketfish HD Webcam USB -- audio only, scrambled image (using built-in 10.4 UVC driver)

Orange Micro iBOT FireWire -- scrambled image (using built-in 10.4 IIDC driver)