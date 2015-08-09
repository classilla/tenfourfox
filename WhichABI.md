# PowerPC: one architecture, many ABIs #

The PowerPC specification does not define an application binary interface, which is important for people trying to use TenFourFox JIT backends on non-OS X systems such as Linux PPC, AIX, etc. By default (if `JS_CPU_PPC_OSX` is set), TenFourFox JIT backends generate code which is ABI-compliant with Mac OS X. Unfortunately, this code is unlikely to work on systems that do not implement the same ABI. Since there are few documents collecting the various ABI used by a particular PowerPC-compatible operating system, this document tries to pull this information together for the convenience of porters.

Most PPC operating systems of recent provenance are either based on IBM's PowerOpen (Mac OS X, AIX, System i), or on UNIX System V "SysV" ABI (Linux, other BSDs, AmigaOS). This is an excellent comparison of OS X and SysV ABIs: http://www.engr.uconn.edu/~zshi/course/cse4903/refs/ppc_inst.pdf

Copies of the SysV ABI reference documentation are available many places for a variety of executable formats, including http://math-atlas.sourceforge.net/devel/assembly/elfspec_ppc.pdf

**Please note that TenFourFox is specifically for Mac OS X; this document would be of most relevance to people porting standard Firefox or SeaMonkey to a PowerPC platform running some other operating system using TenFourFox-originated code. Please help maintain this list by adding (reliable) links to documentation on a particular ABI, or the ABI for your operating system.**


---


## AIX ##
PowerOpen http://www.ibm.com/developerworks/library/pa-nlaug04-introembeddev/index.html

## BeOS ##
Be ABI (need docs)

## AmigaOS 4, MorphOS and compatible ##
Legacy 68K for code that must call 68K libraries; SysV otherwise. See http://wiki.freepascal.org/AmigaOS and http://wiki.freepascal.org/MorphOS

## Linux PPC ##
SysV

## Mac OS, Mac OS X ##
modified PowerOpen http://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/LowLevelABI/000-Introduction/introduction.html

## NetBSD/macppc ##
SysV http://gcc.gnu.org/ml/gcc/2000-12/msg00309.html (other BSDs should also be SysV)

## IBM System i ##
PowerOpen

## WarpOS ##
modified PowerOpen