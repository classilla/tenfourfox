# Contributing to TenFourFox (and fixing problems)

TenFourFox needs contributors to maintain its code, since we are a fork of Firefox and disconnected from current ESRs for technical reasons. Here's what we need and don't need.

## We don't need bug reports or feature requests

At least, we don't need them _here_. If you are an end-user and not an official contributor, **post requests for end user support to [our official Tenderapp Support area](http://tenfourfox.tenderapp.com). The Github issues page is a worklist, not a support forum.**

One of our helpful _volunteer_ staff will help triage your issue and determine if it should be on the worklist on your behalf. Don't do this yourself: most of the time people are wrong about this. Seriously.

But, if you've got a bug report or feature request _and_ a patch you'd like to submit, then read on.

## We don't need patches that break the core platform

**The core platform is Power Macs running 10.4 with `gcc` 4.8.** Any proposed patch, no matter how wonderful, no matter how essential, that breaks the core platform is instantly rejected. If your patch was tested on the core platform and does work, say so (see below); this will speed up acceptance. However, if you are uncertain and you can't test, then please also say so. The maintainers will be a lot less unhappy with you if you warned them your patch might be suss than if you start breaking the main build unexpectedly because we trusted you and accepted your pull. Compile times are slow and we don't have continuous integration, so a bad patch that gets accidentally accepted may waste a lot of time.

If your patch is for another platform, you are expected _not_ to change the PowerPC OS X code without a good reason, even if you think doing so is necessary and/or harmless. Because we have a limited testing capacity, we don't alter working code that works on the core platform unless it's a change that will benefit the core platform. If you want your platform in there too, put `#ifdef`s around your code, please.

## We don't need patches we have to change

There are rather few of us who work on this browser nowadays and our time is limited. Please make sure your patch matches the "house style" of the file(s) you're changing, and if we ask for additional changes, please do them instead of expecting us to (the same as Mozilla's standard policy).

## We do need whatever tests you can run

Please at minimum try your patch in a debug build of the browser to start with. New non-fatal assertions should be avoided unless you have a good reason or you believe the non-fatal assertion is spurious. On the other hand, fatal assertions, where the browser kills itself after the assertion triggers, will not be accepted under any circumstances. Please do not remove existing assertions unless you can prove to our satisfaction that they are no longer necessary.

Mochitests and reftests do not currently work reliably, but we do expect layout and rendering patches to have test cases. Attach them to the issue; they don't need to be in the pull request.

However, if you make changes to JavaScript, you _must_ run both the JIT test suite and the conformance test suite before making a pull request. There should be _no failures_ or your patch will not be accepted, though we will give leeway for slow tests on the conformance suite on slow systems. We generally require these commands be run _on a debug build_, in order:

```
cd js/src/jit-test
./jit_test.py --ion -f ../../../obj-ff-dbg/dist/bin/js
cd ../tests
./jstests.py --jitflags=ion --run-slow-tests ../../../obj-ff-dbg/dist/bin/js
```

On our build Quad G5, we usually throw in a `-j3` too to speed it up. If you don't post evidence you ran the tests (a cut and paste from your terminal window is sufficient), we won't accept your change.

## We do need patches from Mozilla

Adapting later patches from Mozilla to maintain feature parity is always appreciated, because this maintains browser consistency. Please include the bug number. If substantial changes were needed, or you could only adapt a portion, please be detailed about the differences.

If the patch you are adapting has tests, you can include or not include them at your option _except_ if they are for JavaScript; those you _must_ include, and your patch must pass them as well as the existing tests.

## Other notes

Please be nice to us. We may not be able to review your patch immediately, and we may disagree on whether we want it. Please accept these decisions in good faith even if you don't concur.

We have a limited capacity for adding locale strings. If there is a way you can add your feature and avoid adding more strings that need translation, this will be exceedingly preferable.

Try not to add too much bulk to the JavaScript-based chrome unless your feature would be infeasible to implement otherwise. Our JIT is fast, but stil only a fraction of the speed of native code. If you can reasonably write it in C++, everyone will be happier.

Your patches may be reverted without warning if there is evidence of a bug, an unjustifiable drop in performance or build bustage, and you will be asked to fix the patch and resubmit. Please take this as a compliment: we really do want your work in the browser!

## Thank you!!


