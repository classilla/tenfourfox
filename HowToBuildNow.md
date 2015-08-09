**This document only covers the `mozilla-esr10` and `mozilla-esr17` branches, from which 10.4Fx 10.0.x and 17.0.x were built. Therefore, it is mostly obsolete. For 24.0 and higher, see HowToBuildRightNow.**

## Warning ##

These build instructions are always subject to change. You should be familiar with [how Mozilla offers its source code and how to build Mozilla applications](https://developer.mozilla.org/en/Developer_Guide) before you attempt these steps.

These instructions do not apply to the legacy `mozilla-2.0` branch, from which TenFourFox 4.0.x is built. For that, see HowToBuild.

## Prerequisites for both unstable and stable branch builders ##

10.4Fx is currently built from Mozilla's Mercurial repository with our own changesets applied on top. This is not a task for the faint of heart, but here's how we do it. The stable branch requires the steps below; the unstable branch requires these steps and a few more.

  1. At minimum you will need a G4 or G5 (G5 recommended), 10.4.11, Xcode 2.5, 1GB of RAM and 10GB disk space. The build should work on a G3, but has not been tested on it. Just for your interest, TenFourFox is built on a quad G5 with 8GB of RAM, because compilers like RAM. In this configuration, with Energy Saver set to Highest Performance, it takes approximately 90 minutes to kick out a single architecture build.
    * The only currently supported compiler for ESR10 and ESR17 is `gcc` 4.0.1, which comes with Xcode 2.5, although Leopard's Xcode 3 compiler is known to work. Although some later `gcc` versions can be used on Tiger, and will build these versions of TenFourFox, you should read the notes in [issue 52](https://code.google.com/p/tenfourfox/issues/detail?id=52) first. The stable branch release binaries are built with `gcc` 4.0.1 and we will assume you are using it here.
    * Building on 10.5.8 (and/or with Xcode 3) should still be possible, but has not been well tested since version 17. Please file issues _with patches_ if this isn't working.
    * It _should_ be possible to cross-build 10.4Fx on 10.6 using Xcode 3.x. We've never tried this; please try it and let us know. It is definitely _not_ possible to build it on 10.7 and later (thanks a lot, Apple).
  1. Install [MacPorts](http://www.macports.org/install.php), using the Tiger `dmg` for 10.4 or the Leopard `dmg` for 10.5 (Fink users, see below). Note that MacPorts has stopped offering the Tiger package openly, but you can still get it from https://distfiles.macports.org/MacPorts/ (2.0.4 is the last official version, which you can then immediately `selfupdate`).
  1. We need to install not only Mercurial, but Mozilla's preferred `autoconf` and a newer GNU `make` to get around various bugs in Tiger's included version. Get a cup of coffee, because MacPorts likes to install everything else as a prereq for everything else.
    1. `sudo port -v selfupdate`
    1. `sudo port install mercurial libidl autoconf213 gmake python25 py25-zlib freetype`
  1. For Tiger builders _building the stable branch only_, install the [Xcode 3 linker](http://tenfourfox.googlecode.com/files/ldx3.zip), ported to 10.4 by Tobias Netzel. You **do not need** this to build the _unstable_ branch (see HowToBuildRightNow). This can be done in one of two ways:
    1. _Riskier:_ Download it and replace your old linker at `/usr/bin/ld` with this one (renaming it). Save your old linker first. All of your software will now be linked with it, which does generate binaries and `dylib`s that are still compatible with 10.4.
    1. _Safer:_ Download it and save it as `/usr/bin/ldx3`. Rename `/usr/bin/ld` to `/usr/bin/ld32` and move on to grabbing source (we'll give you the next step there).

## Building the stable release from the Mozilla ESR ##

Mozilla's most current stable ESR is the basis for our **stable** branch These instructions assume it is ESR 17, although by the time you read this 17 will be exiting support. These instructions will also work if you use ESR 10, assuming you are using ESR 10 changesets. **Neither TenFourFox 10 nor 17 are supported anymore. Do not submit bug reports for these versions.**

  1. In your nice fat source drive, `hg clone http://hg.mozilla.org/releases/mozilla-esr17` (or the desired revision).
  1. Grab the most current **_stable_** (not _unstable_) changesets from the Downloads tab and unzip them somewhere.
  1. Serially, in numerical order, `hg import` each changeset. This is the most difficult step because some source files may require manually merging individually and then resolving them with `hg resolve -m` afterwards.
  1. **If you chose the _Safer_ approach above:** now, copy `SHIM.ld` (this is added by the changesets to the repo's root directory) to `/usr/bin/ld` and make it executable with `chmod +x /usr/bin/ld`. Make sure you moved your old `ld` to `ld32` first! Your linker is now dynamically switchable. If the `LD64` environment variable is set to `1`, the Xcode 3 linker will be used; otherwise, the Tiger 32-bit linker will be used like usual. The Mozilla build system knows how to toggle this variable. It will have no effect if you went for _Riskier_. **You do not need this step if you are only building the unstable release.**
  1. Select your desired configuration (any of the `*.mozcfg` files) and copy it to `.mozconfig` in the root of the repo. _Prior to Mozilla 9, this could be in `~/.mozconfig` too; as of Fx9 and later, Mozilla **requires** that this file only exist in the repo root._ These configurations should be self-explanatory. For the gory details, see [Configuring Build Options](https://developer.mozilla.org/en/configuring_build_options) at MDN, but in general, you should avoid changing the standard build configurations unless you know exactly what you are doing. **Use the `mozconfig`s that came with this most current revision if at all possible, because the options are periodically upgraded and changed as the build system gets modified. In particular do not use the old `mozconfig`s from 10.4Fx 4.0.x with 5 and up; they will fail inexplicably.**
    * **G4 and G5 owners:** if you want to test the AltiVec (VMX) code paths apart from the standard `mozcfg` files, you should include `--enable-tenfourfox-vmx` in your custom `.mozconfig` or it will be compiled without AltiVec/VMX acceleration. Also, if you are not using Xcode 2.5's `gcc-4.0`, you may need to add `-faltivec` to the compiler command lines in your chosen `mozconfig`.
    * **G5 owners _ONLY_:** if you want to test the G5-specific code paths apart from the standard `G5.mozcfg`, you should include `--enable-tenfourfox-g5` in your custom `.mozconfig` or the regular code paths will be used instead of the G5-specific ones. This does _not_ enable VMX; if you want that, specify it too. You may also need to add `-D_PPC970_` to your compiler strings so that non-Mozilla libraries and JavaScript properly select the correct architecture optimizations. You don't need this, but the browser will not run as well if you don't.
    * **Intel owners _ONLY_:** There is currently no supported debug configuration. The provided `intel.mozcfg` is an opt build only.
  1. (Optional but recommended) Edit `netwerk/protocols/http/OptimizedFor.h` and set the string to something human-readable about the configuration you're building for. This string should be relatively short, and will appear after the `TenFourFox/` in the user agent string.
  1. (Optional) If you want to change the reported version numbers (say, to get rid of that `pre` tag), alter `browser/config/version.txt` for the reported browser version, and `config/milestone.txt` for the reported Gecko version. If you change `config/milestone.txt`, you should also make sure `js/src/config/milestone.txt` matches it, if it exists. _You should revert these changes before pulling source again or you will have to merge them!_
  1. If you are cleaning out an old build, fresh the tree first with:
    * `gmake -f client.mk clean`
    * `find obj-ff-dbg/ -name 'config.*' -print | xargs rm`
    * `rm configure`
  1. `autoconf213`
  1. `gmake -f client.mk build`

## Building from a tarball ##

Depending on the space you have, or your general antipathy towards Mercurial, or your need for an old version of Firefox, you may prefer to build from one of the source archives. The easiest way to do this is to download the archive and expand it, then turn it into a repo with the following (done at the root of the unpacked archive):

  * `hg init`
  * `hg add`
  * `hg commit`

This will create a new blank repo, add everything to it, and then commit. Note that the commit does not restore history; there _is_ no history. Instead, it is as if you started from whole cloth. On the other hand, the resulting repo is considerably smaller and probably easier and faster to work with (but you should _not_ do this if you plan to do development, since you will probably want that history if you screw up).

Once you've done that, resume from step 2 above, since this will now act as your "cloned repo." For old versions of Firefox, you should probably use the 10.4Fx patches that correspond to that rather than the most current changesets, obviously.

## Running and debugging ##

If the build worked, try out your binary in `gdb`:

  * `cd obj-ff-dbg/dist/TenFourFox.app/Contents/MacOS` (or, if in Debug mode, `TenFourFoxDebug.app`)
  * `gdb firefox` (older releases used `firefox-bin`)
  * At the `(gdb)` prompt, `run`

If the build didn't work and you got lots of linker errors, make sure that you properly installed the Xcode 3 linker; the Xcode 2.5 linker will not work.

If the build appeared to work, but the browser crashes in an unusual `objc` symbol when you try to run it, you may have encountered [issue 169](https://code.google.com/p/tenfourfox/issues/detail?id=169) which is due to incorrect linker code generation. This is mostly a problem for 18.0 and later; although the underlying cause is also present in versions 15.x through 17.x, they are not materially affected by it.

## Alternative: Build with Fink _(experimental)_ ##

If you prefer Fink to MacPorts, David Fang is maintaining a Fink package. You should consider this package **experimental.** Install Fink and the unstable tree, and do `fink install tenfourfox`. This will install all prerequisites and build the browser, and a `.deb` will be generated. You can start the executable from `/Applications/Fink/TenFourFox.app`. This may not yet be available for the most current version.

## Keeping up ##

Your repo is now a fully functional clone of the Firefox source repo with the patches for 10.4Fx. If you want to use this as your basis to do additional pulls against Mozilla's repo, you can (after committing your local changes, of course), but you should `hg rebase` after each pull so that the local TenFourFox changesets float to the top.

Inevitably there will be merge conflicts, which you will need to manually resolve, mark with `hg resolve -m` and then continue the rebase with `hg rebase --continue`. **NEVER `hg merge`!**

Once the rebase is complete, you will be able to continue building and working with the repo in a sane state. Like any sane SCM, merge changes you made will be reflected in your changesets.