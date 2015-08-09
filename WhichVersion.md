TenFourFox comes in tuned builds for specific processor families. Choosing the wrong one could make the application crash, or run poorly. While the G3 version is generic and will run on any supported Macintosh, it is also the poorest performer on later Power Macs; similarly, you cannot run the G4 or G5 versions on a G3 as the application will behave incorrectly.

Here's how to select which one you need:

  * G3 and G5 owners, just download the G3 and/or G5 build, respectively. These versions run on any G3 or G5 Power Macintosh.

  * G4 owners, you need to determine if your G4 is a 7450-series CPU ("G4e"), such as the 744x or 745x series, or a 7400-series CPU, such as the 7400 and 7410. Typically the "G4e" series of CPU are in most G4s at and over 733MHz.

> The wrong version will work on your machine, but will not run as well. The easiest way to find out which version you should use is to open `Terminal.app` and type `machine`. Your output will probably look like this:

```
[old-sawtooth]$ machine
ppc7400

[new-ibook]$ machine
ppc7450
```

> Then grab either the 7400 or 7450 build based on the result.

**If you do not see `ppc750`, `ppc7400`, `ppc7450` or `ppc970`, then you do not have a Power Mac.** For example, many Intel Macs report `i486`. **TenFourFox is not officially supported on Intel Macs.** However, many users report the G3 version appears to work for them, but slowly, because it must run under Rosetta. Other architecture builds may crash. You are strongly advised to also read [our FAQ and the question about running 10.4Fx on an Intel Mac](AAATheFAQ.md).