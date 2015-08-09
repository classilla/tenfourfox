**This document only covers the `mozilla-2.0` branch, from which 10.4Fx 4.0.x is built. Therefore, it is mostly obsolete. For 5.0 and higher, see HowToBuildNow.**

## Warning ##

These build instructions are always subject to change. You should be familiar with [how Mozilla offers its source code and how to build Mozilla applications](https://developer.mozilla.org/en/Developer_Guide) before you attempt these steps.

## Prequisites ##

10.4Fx is currently built from Mozilla's Mercurial repository with our own changesets applied on top. This is not a task for the faint of heart, but here's how we do it.

  1. At minimum you will need a G4 or G5 (G5 recommended), 10.4.11, 1GB of RAM and 10GB disk space. The build should work on a G3 or 10.5.8, but is not tested in either configuration. You also need Xcode 2.5 or higher. Just for your interest, TenFourFox is built on a quad G5 with 8GB of RAM, because compilers like RAM. In this configuration, with Energy Saver set to Highest Performance, it takes approximately 90 minutes to kick out a single architecture build.
  1. Install [MacPorts](http://www.macports.org/install.php), using the Tiger dmg. We need to install not only Mercurial, but Mozilla's preferred `autoconf` and a newer GNU `make` to get around various bugs in Tiger's included version. Get a cup of coffee, because MacPorts likes to install everything else as a prereq for everything else.
  1. `sudo port -v selfupdate`
  1. `sudo port install mercurial libidl autoconf213 gmake python py25-zlib py25-hashlib freetype`

## Building from the stable `mozilla-2.0` ##

Once that's done, your system is ready to build some code. Currently, 10.4Fx 4.0 is considered "stable" (ha ha ha), and is built from the "stable" (har har har) `mozilla-2.0` branch. Right now these steps are entirely manual. At some point we will (at least partially) automate this.

  1. In your nice fat source drive, `hg clone http://hg.mozilla.org/releases/mozilla-2.0` (or the desired revision).
  1. Grab the most current changesets from the Downloads tab and unzip them somewhere.
  1. Serially, in numerical order, `hg import` each changeset. This is the most difficult step because some source files may require manually merging individually and then resolving them with `hg resolve -m` afterwards.
  1. Select your desired configuration (any of the `*.mozcfg` files) and copy it to `~/.mozconfig`. These configurations should be self-explanatory. For the gory details, see [Configuring Build Options](https://developer.mozilla.org/en/configuring_build_options) at MDN, but in general, you should avoid changing the standard build configurations unless you know exactly what you are doing.
    * **G4 and G5 owners:** if you want to test the AltiVec (VMX) code paths apart from the standard `mozcfg` files, you should include `--enable-tenfourfox-vmx` in your custom `.mozconfig` or it will be compiled without AltiVec/VMX acceleration.
    * **G5 owners _ONLY_:** if you want to test the G5-specific code paths apart from the standard `G5.mozcfg`, you should include `--enable-tenfourfox-g5` in your custom `.mozconfig` or the regular code paths will be used instead of the G5-specific ones. This does _not_ enable VMX; if you want that, specify it too.
  1. (Optional but recommended) Edit `netwerk/protocols/http/OptimizedFor.h` and set the string to something human-readable about the configuration you're building for. This string should be relatively short, and will appear after the `TenFourFox/` in the user agent string.
  1. (Optional) If you want to change the reported version numbers (say, to get rid of that `pre` tag), alter `browser/config/version.txt` for the reported browser version, and `config/milestone.txt` for the reported Gecko version. _You should revert these changes before pulling source again or you will have to merge them!_
  1. If you are cleaning out an old build, fresh the tree first with:
    * `gmake -f client.mk clean`
    * `rm -f obj-*/config.* configure`
  1. `autoconf213`
  1. `gmake -f client.mk build`

## Running and debugging ##

If the build worked, try out your binary in `gdb`:

  * `cd obj-ff-dbg/dist/TenFourFox.app/Contents/MacOS` (or, if in Debug mode, `TenFourFoxDebug.app`)
  * `gdb firefox-bin`
  * At the `(gdb)` prompt, `run`

## Alternative: Build with Fink _(experimental)_ ##

If you prefer Fink to MacPorts, David Fang is maintaining a Fink package. You should consider this package **experimental.** Install Fink and the unstable tree, and do `fink install tenfourfox`. This will install all prerequisites and build the browser, and a `.deb` will be generated. You can start the executable from `/Applications/Fink/TenFourFox.app`.

## Building old betas with older changesets ##

This is not recommended for a variety of reasons, but you can use old beta changesets as long as you match them to the appropriate revision (to avoid confusion over which changeset is in use, we tag these by date).

## Keeping up ##

Your repo is now a fully functional clone of the Firefox source repo with the patches for 10.4Fx. If you want to use this as your basis to do additional pulls against Mozilla's repo, you can (after committing your local changes, of course), but you should `hg rebase` after each pull so that the local TenFourFox changesets float to the top.

Inevitably there will be merge conflicts, which you will need to manually resolve, mark with `hg resolve -m` and then continue the rebase with `hg rebase --continue`. **NEVER `hg merge`!**

Once the rebase is complete, you will be able to continue building and working with the repo in a sane state. Like any sane SCM, merge changes you made will be reflected in your changesets.