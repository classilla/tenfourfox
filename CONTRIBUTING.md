# Contributing to InterWebPPC (and fixing problems)

InterWebPPC needs contributors to maintain its code, since we are a fork of Firefox and disconnected from current ESRs for technical reasons. Here's what we need and don't need.

## We don't need bug reports or feature requests

## We don't need patches that break the core platform
**The core platform is Power Macs running 10.4 with `gcc` 4.8.** 

## We don't need patches we have to change

## We do need patches from Mozilla

Adapting later patches from Mozilla to maintain feature parity is always appreciated, because this maintains browser consistency. Please include the bug number. If substantial changes were needed, or you could only adapt a portion, please be detailed about the differences.

If the patch you are adapting has tests, you can include or not include them at your option _except_ if they are for JavaScript; those you _must_ include, and your patch must pass them as well as the existing tests.

## Thank you!!


