**This document only covers the `mozilla-esr38` branch, from which TenFourFox 38 is built. It does not cover earlier versions (see HowToBuildNow) or subsequent ones, and it does not cover unstable releases based on Mozilla 39.0+.**

## Warning ##

These build instructions are always subject to change. You should be familiar with [how Mozilla offers its source code and how to build Mozilla applications](https://developer.mozilla.org/en/Developer_Guide) before you attempt these steps.

## Prerequisites ##

10.4Fx is currently built from Mozilla's Mercurial repository with our own changesets applied on top. This is not a task for the faint of heart, but here's how we do it.

  1. At minimum you will need a G4 or G5 (G5 recommended), 10.4.11, Xcode 2.5, 1.5GB of RAM and 10GB disk space. The build should work on a G3, but has not been tested on it. Just for your interest, TenFourFox is built on a quad G5 with 16GB of RAM, because compilers like RAM. In this configuration, with Energy Saver set to Highest Performance, it takes approximately two hours to kick out a single architecture build, and a few minutes longer for a debugging build. Plan accordingly.
    * Although Mozilla 38 requires `gcc` 4.7 or higher, TenFourFox is actually still built with `gcc` 4.6.x (specifically 4.6.3 or 4.6.4), from MacPorts (see below), using a compatibility shim. However, although `gcc` 4.0.1 and `gcc` 4.2 are no longer supported, you must still install Xcode for certain other prerequisites. Later versions of `gcc` have been used in limited situations, and may work, but are not yet supported -- if you use one of these, remove the compatibility shim from the changesets first before applying them; see below. (4.8 is available from MacPorts also, and does work on PowerPC.)
    * Building on 10.5.8 and/or with Xcode 3 should work, but **linking against the 10.5 SDK is not supported.** Note that the browser can still be built on 10.5.8, and will still _run_ on 10.5.8, but the only allowed target will be a _10.4_-compatible browser.
      * If your compiler is compiled for 10.5, the browser will use the 10.4 SDK, but link against your 10.5-only `libgcc` and `stdc++`. If you intend to use your build on a 10.4 system, you will need to replace them with 10.4-compatible libraries. The easiest source is a TenFourFox binary package; see below under **Distributing the executable**. It is also possible, though involved, to make a cross-building `gcc`; see [issue 52](https://code.google.com/p/tenfourfox/issues/detail?id=52).
    * `clang` is not supported. However, it may be possible to do a cross-build on 10.6.8 using a cross-compiling version of `gcc`. Good luck, let us know if it works. It is _not_ possible to build 10.4Fx on 10.7 or any later version of OS X.
  1. Install [MacPorts](http://www.macports.org/install.php), using the Tiger `dmg` for 10.4 or the Leopard `dmg` for 10.5 (Fink users, see below). Note that MacPorts does not always have the most current release up to date for 10.4 or 10.5, but you can still get whatever the most recently updated historical version was from https://distfiles.macports.org/MacPorts/ -- you need only grab the most recent 10.4 or 10.5 version available, because we will immediately force it to self-update in the next step (read on).
  1. We need to install not only Mercurial, a new Python and a new `gcc`, but we'll also need Mozilla's preferred `autoconf` and a newer GNU `make` to get around various bugs in Tiger's included version. Get a cup of coffee, because MacPorts likes to install everything else as a prereq for everything else.
    1. `sudo port -v selfupdate`
    1. `sudo port install mercurial libidl autoconf213 gmake python27 gcc46 freetype`
      * MacPorts' `gcc46` package also includes updated bintools, including its own copy of the Xcode 3 linker, but with a bug fix to enable TenFourFox's `XUL` to link correctly. If your `gcc46` port was built on or prior to December 2012, you probably have [a version with the bug in it](https://trac.macports.org/ticket/37300). At minimum update `ld64`, or just update the whole compiler toolchain entirely. See [issue 52](https://code.google.com/p/tenfourfox/issues/detail?id=52).
      * The old ported Xcode 3 `ld` used to build TenFourFox 17 and earlier is no longer needed.
  1. Somewhere in the 31-37 timeframe, stripping builds created with `gcc` 4.6 started to fail due to what appears to be a compiler bug. To fix this requires a modified `strip` binary (renamed `strip7` so it does not conflict with the regular `strip`) that ignores the variant `N_SECT`s this compiler can generate. You should not use this strip tool for other purposes, as it is intentionally loose with the specification, and you do not need to install it if you are only building a debug or non-stripped build for your own use. Decompress the binary and put it in `/opt/local/bin/strip7` (the configure script is hardcoded to this location). You can get it from [SourceForge](http://sourceforge.net/projects/tenfourfox/files/tools/strip7-104fx.tar.gz/download).
  1. Finally, you must install the TenFourFox debugger, because the `gdb` available with any PowerPC Xcode does not properly grok debugging symbols generated by later `gcc` versions. At least patchlevel 2 is required for the current version of 10.4Fx. Decompress and copy the binary to `/usr/local/bin/gdb7` or wherever it is convenient. Although you can use it to replace your current `gdb`, it's probably safer that you do not. You can get it from [SourceForge](http://sourceforge.net/projects/tenfourfox/files/tools/gdb768-104fx-2.tar.gz/download).

## Building the stable release from the Mozilla ESR ##

Mozilla's most current stable ESR is the basis for our **stable** branch (as opposed to the **unstable**, described below). As of this writing, it is ESR 38. These instructions were slightly different for ESR 24 and 31, which we don't support anymore; if you have a need to build these, see HowToBuildRightNow (do not submit bug reports for these versions).

  1. In your nice fat source drive, `hg clone http://hg.mozilla.org/releases/mozilla-esr38` (or the desired revision).
    * Did the Mozilla tree change after you cloned it? If your changesets are against tip, **STOP.** Do an `hg pull` and `hg up` right now to make sure your tree is current.
  1. Grab the most current **_stable_** (not _unstable_) changesets from [the TenFourFox SourceForge download repository](https://sourceforge.net/projects/tenfourfox/files/) and unzip them somewhere.
  1. Serially, in numerical order, `hg import` each changeset. This is the most difficult step because some source files may require manually merging individually and then resolving them with `hg resolve -m` afterwards.
  1. Select your desired configuration (any of the `*.mozcfg` files) and copy it to `.mozconfig` in the root of the repo. _Prior to Mozilla 9, this could be in `~/.mozconfig` too; as of Fx9 and later, Mozilla **requires** that this file only exist in the repo root._ These configurations should be self-explanatory. For the gory details, see [Configuring Build Options](https://developer.mozilla.org/en/configuring_build_options) at MDN, but in general, you should avoid changing the standard build configurations unless you know exactly what you are doing. **Use the `mozconfig`s that came with this most current revision if at all possible, because the options are periodically upgraded and changed as the build system gets modified. In particular do not use the old `mozconfig`s from 10.4Fx 4.0.x with 5 and up; they will fail inexplicably.**
    * **G4 and G5 owners:** if you want to test the AltiVec (VMX) code paths apart from the standard `mozcfg` files, you should include `--enable-tenfourfox-vmx` in your custom `.mozconfig` or it will be compiled without AltiVec/VMX acceleration.
    * **G5 owners _ONLY_:** if you want to test the G5-specific code paths apart from the standard `G5.mozcfg`, you should include `--enable-tenfourfox-g5` in your custom `.mozconfig` or the regular code paths will be used instead of the G5-specific ones. This does _not_ enable VMX; if you want that, specify it too. You may also need to add `-D_PPC970_` to your compiler strings so that non-Mozilla libraries and JavaScript properly select the correct architecture optimizations. You don't need this, but the browser will not run as well if you don't.
    * **Intel owners _ONLY_:** **Intel builds for TenFourFox 38 do not work.** You can fix this! Good luck; submit patches if you get it operational.
  1. (Optional but recommended) Edit `netwerk/protocols/http/OptimizedFor.h` and set the string to something human-readable about the configuration you're building for. This string should be relatively short, and will appear after the `TenFourFox/` in the user agent string.
  1. (Optional) If you want to change the reported version numbers (say, to get rid of that `pre` tag), alter `browser/config/version.txt` for the reported browser version, and `config/milestone.txt` for the reported Gecko version. _You should revert these changes before pulling source again or you will have to merge them!_
  1. If you are cleaning out an old build, be sure to `rm -rf configure obj-ff-dbg/` first. Then,
  1. `autoconf213`
  1. `gmake -f client.mk build`

## Known build issues ##

  * Until [issue 202](https://code.google.com/p/tenfourfox/issues/detail?id=202) is fixed, you will get spurious errors setting up the Python environment. You can ignore these for now.
  * You will receive warnings about `N_SECT` while linking XUL. These are harmless. If you actually get an error and it doesn't build, then somehow you are using the original `strip`. Check your binaries carefully.

## Building from a tarball ##

Depending on the space you have, or your general antipathy towards Mercurial, or your need for an old version of Firefox, you may prefer to build from one of the source archives. The easiest way to do this is to download the archive and expand it, then turn it into a repo with the following (done at the root of the unpacked archive):

  * `hg init`
  * `hg add`
  * `hg commit`

This will create a new blank repo, add everything to it, and then commit. Note that the commit does not restore history; there _is_ no history. Instead, it is as if you started from whole cloth. On the other hand, the resulting repo is considerably smaller and probably easier and faster to work with (but you should _not_ do this if you plan to do development, since you will probably want that history if you screw up).

Once you've done that, resume from step 2 above, since this will now act as your "cloned repo." For old versions of Firefox, you should probably use the 10.4Fx patches that correspond to that rather than the most current changesets, obviously.

## Building the unstable release from `mozilla-release` ##

**The unstable release is not supported with `gcc` 4.6.** That said, you can still try to build it with the existing 4.6 compatibility shim if you're that blessed with spare time. The unstable version is built from the bleeding edge Mozilla release, which is always `mozilla-release`, whether it still works with TenFourFox or not. The steps are the same as above, so you should make sure you can build a functional stable release binary before you attempt to build an unstable one.

## Running and debugging ##

If the build worked, try out your binary in the TenFourFox debugger. We will assume you installed it to `/usr/local/bin/gdb7`:

  * `cd obj-ff-dbg/dist/TenFourFox.app/Contents/MacOS` (or, if in Debug mode, `TenFourFoxDebug.app`)
  * `gdb7 firefox`
  * At the `(gdb)` prompt, `run`

If the build appeared to work, but the browser crashes in an unusual `objc` symbol when you try to run it or quit, you may have encountered [issue 169](https://code.google.com/p/tenfourfox/issues/detail?id=169) which is due to incorrect linker code generation. Make sure you are using the fixed `ld` (see the prerequisites section).

If you receive strange `Die` errors in the debugger and backtraces don't work properly, you need to upgrade your debugger (or you're using the one that Apple provided, which won't work anymore).

### Distributing the executable ###

Because the new compiler links against its own `libgcc` and `libstdc++`, if you intend to make a build to generally distribute or use on another computer, you will need to include these libraries and update the linkage to point to the included copies. The tool `104fx_copy.sh` (in the root) will help you with this. Make it executable with `chmod +x` if necessary, then simply type `./104fx_copy.sh [destination name.app]` and the built binary will be copied to the destination name (which should be the new app bundle filename) and its linkages updated to be internal. This should be the **last** step you do before release since the binary it generates is completely standalone and disconnected from the build system.

**If you built on 10.5 with a compiler that was also built on 10.5, your built browser will only work on 10.5** (despite using the 10.4 SDK) because the `gcc` 4.6.x `libgcc` and `libstdc++` are linked against the 10.5 SDK, not 10.4. The easiest way to solve this problem is to replace `libgcc_s.1.dylib` and `libstdc++.6.dylib` in your browser package with the ones from a real TenFourFox binary and then your build will "just work" on both operating systems. It _is_ possible, though involved, to build a cross-compiling 10.5 `gcc` that will create 10.4-compatible binaries; see [issue 52](https://code.google.com/p/tenfourfox/issues/detail?id=52).

## Alternative: Build with Fink _(experimental)_ ##

If you prefer Fink to MacPorts, David Fang is maintaining a Fink package. You should consider this package **experimental.** Install Fink and the unstable tree, and do `fink install tenfourfox`. This will install all prerequisites and build the browser, and a `.deb` will be generated. You can start the executable from `/Applications/Fink/TenFourFox.app`. This may not yet be available for the most current version.

## Building from `mozilla-beta` or `mozilla-aurora` ##

**Neither branch is supported with `gcc` 4.6.** That said, you can still try to build with the existing 4.6 compatibility shim if you're that blessed with spare time. To build whatever the upcoming release(s) are, use these trees instead (substitute the desired tree for `mozilla-release`). In general, we don't support building from `mozilla-central`, and we usually do not offer Aurora changesets, so you're on your own. The beta branch may work, but will require manual merging of the changesets. Try to use as recent a revision as possible.

## Keeping up ##

Your repo is now a fully functional clone of the Firefox source repo with the patches for 10.4Fx. If you want to use this as your basis to do additional pulls against Mozilla's repo, you can (after committing your local changes, of course), but you should `hg rebase` after each pull so that the local TenFourFox changesets float to the top.

Inevitably there will be merge conflicts, which you will need to manually resolve, mark with `hg resolve -m` and then continue the rebase with `hg rebase --continue`. **NEVER `hg merge`!**

Once the rebase is complete, you will be able to continue building and working with the repo in a sane state. Like any sane SCM, merge changes you made will be reflected in your changesets.