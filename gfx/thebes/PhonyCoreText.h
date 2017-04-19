/* This is where the awesome is -- Apple's Tiger Core Text spread bare for
   the world, like the hottest nerd centerfold ever. This also includes
   necessarily some of the private Core Graphics methods also in 10.4. */

/* Dear Apple, in case you are reading:

   - I intentionally did NOT look at the API headers from Leopard while
     working on this so that I would not be affected by them. This permits
     this to be distributed Tri-License MPL/GPL/LGPL honestly, because it
     is all my own hard, slavish work, and not an Apple proprietary file.
   - This only includes what I need to get this version of Mozilla to build.
     There are lots of other symbols defined that I don't need here.
   - Symbols were dumped initially with nm, and then otool to reconstruct
     the actual calling conventions and structs. Where I could just derive
     them from Mozilla code, they are just that (there were some gimmes), and
     therefore use NSPR types instead of C types.
   - Don't sue me. I love you. I want to have Steve's babies (if I were
     physically capable). I didn't steal your code. Did I mention Stevespawn?
   - Well, okay, maybe not his *babies*. How about cleaning out their old
     machines closet? I can give that old TAM a home. Get it? That was a
     really cool anime joke. Please don't sue people who can make really cool
     anime jokes.

Cameron Kaiser */

#ifndef __PHONYCORETEXT_H
#define __PHONYCORETEXT_H

#ifdef __cplusplus
#define __CKEXTERN extern "C"
#define __CKEXTERNBEGIN extern "C" {
#define __CKEXTERNEND }
#else
#define __CKEXTERN extern
#define __CKEXTERNBEGIN
#define __CKEXTERNEND
#endif

#include <CoreFoundation/CFArray.h>
#include <CoreFoundation/CFData.h>
#include <CoreFoundation/CFDictionary.h>

__CKEXTERNBEGIN

/* Hidden bits and private methods in CoreGraphics that we need */
/* Unfortunately, we still have to use ATSUI workarounds for tables bleh */

/* typedef float CGFloat; */ /* uncomment if needed */
__CKEXTERN uint32_t CGFontGetUnitsPerEm(CGFontRef font);
__CKEXTERN bool CGFontGetGlyphAdvances(CGFontRef font, const CGGlyph glyphs[], size_t count, int advances[]);

/* CoreText private framework */
/* Approximately in order as they appear in gfxCoreTextShaper */

/* Descriptors */

typedef const struct __CTFontDescriptor *CTFontDescriptorRef; /* opaque */
__CKEXTERN const CFStringRef kCTFontFeatureTypeIdentifierKey;
__CKEXTERN const CFStringRef kCTFontFeatureSelectorIdentifierKey;
__CKEXTERN const CFStringRef kCTFontFeatureSettingsAttribute;
__CKEXTERN CTFontDescriptorRef CTFontDescriptorCreateWithAttributes(CFDictionaryRef attribs);
/* we do not have CTFontDescriptorCreateCopyWithAttributes, but we can't
   do ligatures anyway, see Runs */

/* Fonts */

typedef const struct __CTFont *CTFontRef; /* opaque */
__CKEXTERN CTFontRef CTFontCreateWithPlatformFont(ATSFontRef atsfont, float size, const CGAffineTransform *atrans, CTFontDescriptorRef attribs);
__CKEXTERN CTFontRef CTFontCreateWithGraphicsFont(CGFontRef cgfont, float size, const CGAffineTransform *atrans, CTFontDescriptorRef attribs);
__CKEXTERN const CFStringRef kCTFontAttributeName;
__CKEXTERN float CTFontGetSize(CTFontRef font);

/* Lines */

typedef const struct __CTLine *CTLineRef; /* opaque */
__CKEXTERN CTLineRef CTLineCreateWithAttributedString(CFAttributedStringRef str);
__CKEXTERN CFArrayRef CTLineGetGlyphRuns(CTLineRef line);

/* Runs */

typedef const struct __CTRun *CTRunRef; /* opaque */
__CKEXTERN int32_t CTRunGetGlyphCount(CTRunRef run);
__CKEXTERN CFRange CTRunGetStringRange(CTRunRef run);
__CKEXTERN const CGGlyph *CTRunGetGlyphsPtr(CTRunRef run);
__CKEXTERN void CTRunGetGlyphs(CTRunRef run, CFRange range, CGGlyph glyphs[]);
/* we do not have CTRunGetPositionsPtr and friends; we cannot reposition.
   I might do an ATSUI workaround for this if I am really, really prodded.
   However, we can duplicate a lot of it with CTRunGetAdvancesPtr etc. */
__CKEXTERN const CGSize *CTRunGetAdvancesPtr(CTRunRef run);
__CKEXTERN void CTRunGetAdvances(CTRunRef run, CFRange range, CGSize advances[]);
__CKEXTERN const CFIndex *CTRunGetStringIndicesPtr(CTRunRef run);
__CKEXTERN void CTRunGetStringIndices(CTRunRef run, CFRange range, CFIndex si[]);
__CKEXTERN double CTRunGetTypographicBounds(CTRunRef run, CFRange range, float *x, float *y, float *z); /* I suspect ascent/descent/leading */

__CKEXTERNEND
#endif /* __PHONYCORETEXT_H */
