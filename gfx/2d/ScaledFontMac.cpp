/* -*- Mode: C++; tab-width: 20; indent-tabs-mode: nil; c-basic-offset: 2 -*-
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "ScaledFontMac.h"
#ifdef USE_SKIA
#include "PathSkia.h"
#include "skia/include/core/SkPaint.h"
#include "skia/include/core/SkPath.h"
#include "skia/include/ports/SkTypeface_mac.h"
#endif
#include "DrawTargetCG.h"
#include <vector>
#include <dlfcn.h>
#ifdef MOZ_WIDGET_UIKIT
#include <CoreFoundation/CoreFoundation.h>
#endif
#include "../thebes/PhonyCoreText.h"
#include "nsTArray.h"

#ifdef MOZ_WIDGET_COCOA
// prototype for private API
extern "C" {
CGPathRef CGFontGetGlyphPath(CGFontRef fontRef, CGAffineTransform *textTransform, int unknown, CGGlyph glyph);
};
#endif


namespace mozilla {
namespace gfx {

ScaledFontMac::CTFontDrawGlyphsFuncT* ScaledFontMac::CTFontDrawGlyphsPtr = nullptr;
bool ScaledFontMac::sSymbolLookupDone = false;

ScaledFontMac::ScaledFontMac(CGFontRef aFont, Float aSize)
  : ScaledFontBase(aSize)
{
// CTFontDrawGlyphs only exists in 10.7 and up. There is no reason for us
// to look for it knowing it will fail.
  mFont = CGFontRetain(aFont);
  mCTFont = nullptr;
  CTFontDrawGlyphsPtr = nullptr;
#if(0)
  if (!sSymbolLookupDone) {
    CTFontDrawGlyphsPtr =
      (CTFontDrawGlyphsFuncT*)dlsym(RTLD_DEFAULT, "CTFontDrawGlyphs");
    sSymbolLookupDone = true;
  }

  // XXX: should we be taking a reference
  mFont = CGFontRetain(aFont);
  if (CTFontDrawGlyphsPtr != nullptr) {
    // only create mCTFont if we're going to be using the CTFontDrawGlyphs API
    mCTFont = CTFontCreateWithGraphicsFont(aFont, aSize, nullptr, nullptr);
  } else {
    mCTFont = nullptr;
  }
#endif
}

ScaledFontMac::~ScaledFontMac()
{
  if (mCTFont) {
    CFRelease(mCTFont);
  }
  CGFontRelease(mFont);
}

#ifdef USE_SKIA
SkTypeface* ScaledFontMac::GetSkTypeface()
{
  if (!mTypeface) {
    if (mCTFont) {
      mTypeface = SkCreateTypefaceFromCTFont(mCTFont);
    } else {
      CTFontRef fontFace = CTFontCreateWithGraphicsFont(mFont, mSize, nullptr, nullptr);
      mTypeface = SkCreateTypefaceFromCTFont(fontFace);
      CFRelease(fontFace);
    }
  }
  return mTypeface;
}
#endif

// private API here are the public options on OS X
// CTFontCreatePathForGlyph
// ATSUGlyphGetCubicPaths
// we've used this in cairo sucessfully for some time.
// Note: cairo dlsyms it. We could do that but maybe it's
// safe just to use?

already_AddRefed<Path>
ScaledFontMac::GetPathForGlyphs(const GlyphBuffer &aBuffer, const DrawTarget *aTarget)
{
  if (aTarget->GetBackendType() == BackendType::COREGRAPHICS ||
      aTarget->GetBackendType() == BackendType::COREGRAPHICS_ACCELERATED) {
#ifdef MOZ_WIDGET_COCOA
      CGMutablePathRef path = CGPathCreateMutable();
      for (unsigned int i = 0; i < aBuffer.mNumGlyphs; i++) {
          // XXX: we could probably fold both of these transforms together to avoid extra work
          CGAffineTransform flip = CGAffineTransformMakeScale(1, -1);

          CGPathRef glyphPath = ::CGFontGetGlyphPath(mFont, &flip, 0, aBuffer.mGlyphs[i].mIndex);

          CGAffineTransform matrix = CGAffineTransformMake(mSize, 0, 0, mSize,
                                                           aBuffer.mGlyphs[i].mPosition.x,
                                                           aBuffer.mGlyphs[i].mPosition.y);
          CGPathAddPath(path, &matrix, glyphPath);
          CGPathRelease(glyphPath);
      }
      RefPtr<Path> ret = new PathCG(path, FillRule::FILL_WINDING);
      CGPathRelease(path);
      return ret.forget();
#else
      //TODO: probably want CTFontCreatePathForGlyph
      MOZ_CRASH("GFX: This needs implemented 1");
#endif
  }
  return ScaledFontBase::GetPathForGlyphs(aBuffer, aTarget);
}

void
ScaledFontMac::CopyGlyphsToBuilder(const GlyphBuffer &aBuffer, PathBuilder *aBuilder, BackendType aBackendType, const Matrix *aTransformHint)
{
  if (!(aBackendType == BackendType::COREGRAPHICS || aBackendType == BackendType::COREGRAPHICS_ACCELERATED)) {
    ScaledFontBase::CopyGlyphsToBuilder(aBuffer, aBuilder, aBackendType, aTransformHint);
    return;
  }
#ifdef MOZ_WIDGET_COCOA
  PathBuilderCG *pathBuilderCG =
    static_cast<PathBuilderCG*>(aBuilder);
  // XXX: check builder type
  for (unsigned int i = 0; i < aBuffer.mNumGlyphs; i++) {
    // XXX: we could probably fold both of these transforms together to avoid extra work
    CGAffineTransform flip = CGAffineTransformMakeScale(1, -1);
    CGPathRef glyphPath = ::CGFontGetGlyphPath(mFont, &flip, 0, aBuffer.mGlyphs[i].mIndex);

    CGAffineTransform matrix = CGAffineTransformMake(mSize, 0, 0, mSize,
                                                     aBuffer.mGlyphs[i].mPosition.x,
                                                     aBuffer.mGlyphs[i].mPosition.y);
    CGPathAddPath(pathBuilderCG->mCGPath, &matrix, glyphPath);
    CGPathRelease(glyphPath);
  }
#else
    //TODO: probably want CTFontCreatePathForGlyph
    MOZ_CRASH("GFX: This needs implemented 2");
#endif
}

uint32_t
CalcTableChecksum(const uint32_t *tableStart, uint32_t length, bool skipChecksumAdjust = false)
{
    uint32_t sum = 0L;
    const uint32_t *table = tableStart;
    const uint32_t *end = table+((length+3) & ~3) / sizeof(uint32_t);
    while (table < end) {
        if (skipChecksumAdjust && (table - tableStart) == 2) {
            table++;
        } else {
            sum += CFSwapInt32BigToHost(*table++);
        }
    }
    return sum;
}

struct TableRecord {
    uint32_t tag;
    uint32_t checkSum;
    uint32_t offset;
    uint32_t length;
    CFDataRef data;
};

int maxPow2LessThan(int a)
{
    int x = 1;
    int shift = 0;
    while ((x<<(shift+1)) < a) {
        shift++;
    }
    return shift;
}

struct writeBuf
{
    explicit writeBuf(int size)
    {
        this->data = new unsigned char [size];
        this->offset = 0;
    }
    ~writeBuf() {
        delete this->data;
    }

    template <class T>
    void writeElement(T a)
    {
        *reinterpret_cast<T*>(&this->data[this->offset]) = a;
        this->offset += sizeof(T);
    }

    void writeMem(const void *data, unsigned long length)
    {
        memcpy(&this->data[this->offset], data, length);
        this->offset += length;
    }

    void align()
    {
        while (this->offset & 3) {
            this->data[this->offset] = 0;
            this->offset++;
        }
    }

    unsigned char *data;
    int offset;
};

#ifdef __ppc__
#define TAG_CFF  0x43464620
#define TAG_CFF2 0x43464632
#define TAG_HEAD 0x68656164
#else
#define TAG_CFF  0x20464643
#define TAG_CFF2 0x32464643
#define TAG_HEAD 0x64616568
#endif

bool
ScaledFontMac::GetFontFileData(FontFileDataOutput aDataCallback, void *aBaton)
{
#if(0)
    // We'll reconstruct a TTF font from the tables we can get from the CGFont
    CFArrayRef tags = CGFontCopyTableTags(mFont);
    CFIndex count = CFArrayGetCount(tags);

    TableRecord *records = new TableRecord[count];
    uint32_t offset = 0;
    offset += sizeof(uint32_t)*3;
    offset += sizeof(uint32_t)*4*count;
    bool CFF = false;
    for (CFIndex i = 0; i<count; i++) {
        uint32_t tag = (uint32_t)(uintptr_t)CFArrayGetValueAtIndex(tags, i);
        if (tag == TAG_CFF) // 'CFF '
            CFF = true;
        CFDataRef data = CGFontCopyTableForTag(mFont, tag);
        records[i].tag = tag;
        records[i].offset = offset;
        records[i].data = data;
        records[i].length = CFDataGetLength(data);
        bool skipChecksumAdjust = (tag == TAG_HEAD); // 'head'
        records[i].checkSum = CalcTableChecksum(reinterpret_cast<const uint32_t*>(CFDataGetBytePtr(data)),
                                                records[i].length, skipChecksumAdjust);
        offset += records[i].length;
        // 32 bit align the tables
        offset = (offset + 3) & ~3;
    }
    CFRelease(tags);
#else
    // 10.4 doesn't make this easy the way Mozilla wants it, but we'll try.
    // Since this is a raw CGFont, we have none of the work we already did.
    bool CFF = false;
    AutoFallibleTArray<uint8_t,1024> table;
    ByteCount sizer = 0;

    // mFont is a CGFont, and ATSUI won't operate on that, so we need to make
    // it an ATSFontRef first. If this fails, we're dead.
    CFStringRef psName = ::CGFontCopyPostScriptName(mFont);
    ATSFontRef fontRef = ::ATSFontFindFromPostScriptName(psName,
	kATSOptionFlagsDefault);
    CFRelease(psName);
    if (!fontRef || fontRef == kInvalidFont ||
	fontRef == kATSFontRefUnspecified) {
		NS_WARNING("Failed PostScript lookup");
		return false;
    }

    // Next, get the table directory and iterate over it.
    if(::ATSFontGetTableDirectory(fontRef, 0, nullptr, &sizer) == noErr) {
      // Sanity check.
      if (sizer <= 12 || ((sizer-12) % 16) || sizer >= 1024)
        return false;
    } else { return false; }
    table.SetLength(sizer, fallible);

    if (::ATSFontGetTableDirectory(fontRef, sizer,
      reinterpret_cast<void *>(table.Elements()), &sizer) != noErr)
        return false;
    uint32_t count = ((sizer-12) / 16);
    uint32_t offset = (uint32_t)sizer;
    uint32_t *wtable = (reinterpret_cast<uint32_t *>(table.Elements()));
    TableRecord *records = new TableRecord[count];
    for (uint32_t i=3; i<(sizer/4); i+=4) { // Skip header
        uint32_t tag = wtable[i];
        if (tag == TAG_CFF || tag == TAG_CFF2)
            CFF = true;
        // We know the length from the directory, so we can simply import
        // the data. We assume the table exists, and OMG if it doesn't.
	// This is the equivalent for CGFontCopyTableForTag().
        records[i].tag = tag;
        records[i].offset = offset;
	ByteCount dataLength = (ByteCount)wtable[i+3];
	CFMutableDataRef data = ::CFDataCreateMutable(kCFAllocatorDefault,
		dataLength);
	if (!data) return false;
	::CFDataIncreaseLength(data, dataLength); // paranoia
	if(::ATSFontGetTable(fontRef, tag, 0, dataLength,
		::CFDataGetMutableBytePtr(data), &dataLength) != noErr) {
		CFRelease(data);
		return false;
	}
        records[i].data = data;
        records[i].length = (uint32_t)dataLength;
        bool skipChecksumAdjust = (tag == TAG_HEAD); // 'head'
        records[i].checkSum = CalcTableChecksum(
		reinterpret_cast<const uint32_t*>(CFDataGetBytePtr(data)),
                records[i].length, skipChecksumAdjust);
        offset += records[i].length;
        // 32 bit align the tables
        offset = (offset + 3) & ~3;
    }
#endif

    struct writeBuf buf(offset);
    // write header/offset table
    if (CFF) {
      buf.writeElement(CFSwapInt32HostToBig(0x4f54544f));
    } else {
      buf.writeElement(CFSwapInt32HostToBig(0x00010000));
    }
    buf.writeElement(CFSwapInt16HostToBig(count));
    buf.writeElement(CFSwapInt16HostToBig((1<<maxPow2LessThan(count))*16));
    buf.writeElement(CFSwapInt16HostToBig(maxPow2LessThan(count)));
    buf.writeElement(CFSwapInt16HostToBig(count*16-((1<<maxPow2LessThan(count))*16)));

    // write table record entries
    for (CFIndex i = 0; i<count; i++) {
        buf.writeElement(CFSwapInt32HostToBig(records[i].tag));
        buf.writeElement(CFSwapInt32HostToBig(records[i].checkSum));
        buf.writeElement(CFSwapInt32HostToBig(records[i].offset));
        buf.writeElement(CFSwapInt32HostToBig(records[i].length));
    }

    // write tables
    int checkSumAdjustmentOffset = 0;
    for (CFIndex i = 0; i<count; i++) {
        if (records[i].tag == TAG_HEAD) {
            checkSumAdjustmentOffset = buf.offset + 2*4;
        }
        buf.writeMem(CFDataGetBytePtr(records[i].data), CFDataGetLength(records[i].data));
        buf.align();
        CFRelease(records[i].data);
    }
    delete[] records;

    // clear the checksumAdjust field before checksumming the whole font
    memset(&buf.data[checkSumAdjustmentOffset], 0, sizeof(uint32_t));
    uint32_t fontChecksum = CFSwapInt32HostToBig(0xb1b0afba - CalcTableChecksum(reinterpret_cast<const uint32_t*>(buf.data), offset));
    // set checkSumAdjust to the computed checksum
    memcpy(&buf.data[checkSumAdjustmentOffset], &fontChecksum, sizeof(fontChecksum));

    // we always use an index of 0
    aDataCallback(buf.data, buf.offset, 0, mSize, aBaton);

    return true;

}

} // namespace gfx
} // namespace mozilla
