/* -*- Mode: C++; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim: set ts=8 sts=2 et sw=2 tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* WebP for TenFourFox. Actually works on big endian.
   Incorporates original version from bug 600919 with later updates.
   See also bug 1294490. */

#include "nsWEBPDecoder.h"

#include "ImageLogging.h"
#include "gfxColor.h"
#include "gfxPlatform.h"
#include "webp/demux.h"

namespace mozilla {
namespace image {

#if defined(PR_LOGGING)
static PRLogModuleInfo* gWEBPDecoderAccountingLog =
  PR_NewLogModule("WEBPDecoderAccounting");
#else
#define gWEBPDecoderAccountingLog
#endif

nsWEBPDecoder::nsWEBPDecoder(RasterImage* aImage)
  : Decoder(aImage)
  , mDecoder(nullptr)
  , mLastLine(0)
  , mWidth(0)
  , mHeight(0)
  , haveSize(false)
  , mProfile(nullptr)
  , mTransform(nullptr)
{
  MOZ_LOG(gWEBPDecoderAccountingLog, LogLevel::Debug,
         ("nsWEBPDecoder::nsWEBPDecoder: Creating WEBP decoder %p",
          this));
}

nsWEBPDecoder::~nsWEBPDecoder()
{
  MOZ_LOG(gWEBPDecoderAccountingLog, LogLevel::Debug,
         ("nsWEBPDecoder::~nsWEBPDecoder: Destroying WEBP decoder %p",
          this));
}

void
nsWEBPDecoder::InitInternal()
{
  if (!WebPInitDecBuffer(&mDecBuf)) {
    PostDecoderError(NS_ERROR_FAILURE);
    return;
  }

  if (IsMetadataDecode()) {
    return; // don't need a decoder yet
  }

  MOZ_ASSERT(!mImageData, "Shouldn't have a buffer yet");

  // Premultiplied alpha required. We may change the colourspace
  // if colour management is required (see below).
#if MOZ_BIG_ENDIAN
  mDecBuf.colorspace = MODE_Argb;
#else
  mDecBuf.colorspace = MODE_bgrA;
#endif
  mDecBuf.is_external_memory = 1;
  mDecBuf.u.RGBA.rgba = mImageData; // nullptr right now
  mDecoder = WebPINewDecoder(&mDecBuf);
  if (!mDecoder) {
    PostDecoderError(NS_ERROR_FAILURE);
    return;
  }
}

void
nsWEBPDecoder::WriteInternal(const char* aBuffer, uint32_t aCount)
{
  const uint8_t* buf = (const uint8_t*)aBuffer;
  uint32_t flags = 0;

  if (!haveSize) {
    WebPDemuxer *demux = nullptr;
    WebPDemuxState state;
    WebPData fragment;

    if (!aCount) return;

    fragment.bytes = buf;
    fragment.size = aCount;
    demux = WebPDemuxPartial(&fragment, &state);
    if (!demux) {
      // We don't even have enough data to determine if we have headers.
      return;
    }
    if (state == WEBP_DEMUX_PARSE_ERROR) {
      // Hmm.
      NS_WARNING("Parse error on WebP image");
      WebPDemuxDelete(demux);
      return;
    }
    if (state == WEBP_DEMUX_PARSING_HEADER) {
      // Not enough data yet.
      WebPDemuxDelete(demux);
      return;
    }

    flags = WebPDemuxGetI(demux, WEBP_FF_FORMAT_FLAGS);

    // Make sure chunks are available, if we need them.
    if (flags & ICCP_FLAG) {
      // Embedded colour profile chunk.
      if (state != WEBP_DEMUX_DONE) {
        // Not enough data yet.
        NS_WARNING("Waiting for WebP chunks to load");
        WebPDemuxDelete(demux);
        return;
      }
    }

    // Valid demuxer available.
    if (flags & ANIMATION_FLAG) {
// XXX
fprintf(stderr, "Warning: TenFourFox doesn't support animated WebP.\n");
PostDecoderError(NS_ERROR_FAILURE);
return;
    }
    if (flags & ALPHA_FLAG) {
      PostHasTransparency();
    }

    // Handle embedded colour profiles.
    if (!mProfile && (flags & ICCP_FLAG)) {
      if (gfxPlatform::GetCMSOutputProfile()) {
        WebPChunkIterator chunk_iter;

        if (WebPDemuxGetChunk(demux, "ICCP", 1, &chunk_iter)) {
#if DEBUG
          fprintf(stderr, "WebP has embedded colour profile (%d bytes).\n", chunk_iter.chunk.size);
#endif
          mProfile = qcms_profile_from_memory(
            reinterpret_cast<const char*>(chunk_iter.chunk.bytes),
            chunk_iter.chunk.size);
          if (mProfile) {
            int intent = gfxPlatform::GetRenderingIntent();
            if (intent == -1)
              intent = qcms_profile_get_rendering_intent(mProfile);
            mTransform = qcms_transform_create(mProfile,
                                               QCMS_DATA_RGBA_8,
                                               gfxPlatform::GetCMSOutputProfile(),
                                               QCMS_DATA_RGBA_8,
                                               (qcms_intent)intent);
            mDecBuf.colorspace = MODE_rgbA; // byte-swapped later
          }
          WebPDemuxReleaseChunkIterator(&chunk_iter);
        }
      }
    }

    mWidth = WebPDemuxGetI(demux, WEBP_FF_CANVAS_WIDTH);
    mHeight = WebPDemuxGetI(demux, WEBP_FF_CANVAS_HEIGHT);
    // Post our size to the superclass
    PostSize(mWidth, mHeight);
    mDecBuf.width = mWidth;
    mDecBuf.height = mHeight;
    mDecBuf.u.RGBA.stride = mWidth * sizeof(uint32_t);
    mDecBuf.u.RGBA.size = mDecBuf.u.RGBA.stride * mHeight;
    haveSize = true;

    WebPDemuxDelete(demux);
  }

  if (IsMetadataDecode()) {
    // Nothing else to do.
    return;
  }

  if (!mImageData) {
    MOZ_ASSERT(haveSize, "Didn't fetch metadata?");
    nsresult rv_ = AllocateBasicFrame();
    if (NS_FAILED(rv_)) {
      return;
    }
  }
  MOZ_ASSERT(mImageData, "Should have a buffer now");
  MOZ_ASSERT(mDecoder, "Should have a decoder now");
  mDecBuf.u.RGBA.rgba = mImageData; // no longer null
  const VP8StatusCode rv = WebPIAppend(mDecoder, buf, aCount);

  if (rv == VP8_STATUS_OUT_OF_MEMORY) {
    NS_WARNING("WebP out of memory");
    PostDecoderError(NS_ERROR_OUT_OF_MEMORY);
    return;
  } else if (rv == VP8_STATUS_INVALID_PARAM ||
             rv == VP8_STATUS_BITSTREAM_ERROR) {
    NS_WARNING("WebP bitstream error");
    PostDataError();
    return;
  } else if (rv == VP8_STATUS_UNSUPPORTED_FEATURE ||
             rv == VP8_STATUS_USER_ABORT) {
    NS_WARNING("WebP unsupported feature");
    PostDecoderError(NS_ERROR_FAILURE);
    return;
  }

  // Catch any remaining erroneous return value.
  if (rv != VP8_STATUS_OK && rv != VP8_STATUS_SUSPENDED) {
#if DEBUG
    fprintf(stderr, "WebP unexpected parsing error %d\n", rv);
#endif
    PostDecoderError(NS_ERROR_FAILURE);
    return;
  }

  int lastLineRead = -1;
  int width = 0;
  int height = 0;
  int stride = 0;

  uint8_t* data =
    WebPIDecGetRGB(mDecoder, &lastLineRead, &width, &height, &stride);

  // WebP encoded image data hasn't been read yet, return.
  if (lastLineRead == -1 || !data) {
    return;
  }

  // Ensure valid image height & width.
  if (width <= 0 || height <= 0) {
    PostDataError();
    return;
  }

  if (!mImageData) {
    NS_WARNING("WebP y u no haz image");
    PostDecoderError(NS_ERROR_FAILURE);
    return;
  }

  if (lastLineRead > mLastLine) {
    if (mTransform) {
      for (int row = mLastLine; row < lastLineRead; row++) {
        MOZ_ASSERT(!(stride % 4)); // should be RGBA alignment
        uint8_t* src = data + row * stride;
        qcms_transform_data(mTransform, src, src, width);
        for (uint8_t* i = src; i < src + stride; i+=4) {
#if MOZ_BIG_ENDIAN
          // RGBA -> ARGB
          uint8_t a = i[3];
          i[3] = i[2];
          i[2] = i[1];
          i[1] = i[0];
          i[0] = a;
#else
          // RGBA -> BGRA
          uint8_t r = i[2];
          i[2] = i[0];
          i[0] = r;
#endif
        }
      }
    }

    // Invalidate
    nsIntRect r(0, mLastLine, width, lastLineRead - mLastLine);
    PostInvalidation(r);
    mLastLine = lastLineRead;
  }
}

void
nsWEBPDecoder::FinishInternal()
{
  // We should never make multiple frames
  MOZ_ASSERT(GetFrameCount() <= 1, "Multiple WebP frames?");

  // Send notifications if appropriate
  if (!IsMetadataDecode() && (GetFrameCount() == 1)) {
    // Flush the decoder
    WebPIDelete(mDecoder);
    WebPFreeDecBuffer(&mDecBuf);

    PostFrameStop();
    PostDecodeDone();

    mDecoder = nullptr;

    if (mProfile) {
      if (mTransform) {
        qcms_transform_release(mTransform);
        mTransform = nullptr;
      }
      qcms_profile_release(mProfile);
      mProfile = nullptr;
    }
  }
}

} // namespace image
} // namespace mozilla
