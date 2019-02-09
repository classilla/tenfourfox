/* -*- Mode: C++; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim: set ts=8 sts=2 et sw=2 tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
/* Contributor(s):
 *   Vikas Arora <vikasa@google.com> */

#include "nsWEBPDecoder.h"

#include "ImageLogging.h"
#include "gfxColor.h"
#include "gfxPlatform.h"

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

  mDecBuf.colorspace = MODE_bgrA;
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

  if (IsMetadataDecode() || !haveSize) {
    WebPBitstreamFeatures features;
    const VP8StatusCode rv = WebPGetFeatures(buf, aCount, &features);

    if (rv == VP8_STATUS_OK) {
      if (features.has_animation) {
        PostDecoderError(NS_ERROR_FAILURE);
        return;
      }
      if (features.has_alpha) {
        PostHasTransparency();
      }
      // Post our size to the superclass
      if (IsMetadataDecode()) {
        PostSize(features.width, features.height);
      }
      mWidth = features.width;
      mHeight = features.height;
      mDecBuf.width = mWidth;
      mDecBuf.height = mHeight;
      mDecBuf.u.RGBA.stride = mWidth * sizeof(uint32_t);
      mDecBuf.u.RGBA.size = mDecBuf.u.RGBA.stride * mHeight;
      haveSize = true;
    } else if (rv != VP8_STATUS_NOT_ENOUGH_DATA) {
      PostDecoderError(NS_ERROR_FAILURE);
      return;
    } else {
#if DEBUG
      fprintf(stderr, "WebP had unexpected return code: %d\n", rv);
#endif
      return;
    }

    // If we're doing a size decode, we're done.
    if (IsMetadataDecode()) return;
  }

  MOZ_ASSERT(!mImageData, "Already have a buffer allocated?");
  MOZ_ASSERT(haveSize, "Didn't fetch metadata?");
  PostSize(mWidth, mHeight);
  nsresult rv_ = AllocateBasicFrame();
  if (NS_FAILED(rv_)) {
      return;
  }

  MOZ_ASSERT(mImageData, "Should have a buffer now");
  MOZ_ASSERT(mDecoder, "Should have a decoder now");
  mDecBuf.u.RGBA.rgba = mImageData; // no longer null
  const VP8StatusCode rv = WebPIAppend(mDecoder, buf, aCount);

  if (rv == VP8_STATUS_OUT_OF_MEMORY) {
    PostDecoderError(NS_ERROR_OUT_OF_MEMORY);
    return;
  } else if (rv == VP8_STATUS_INVALID_PARAM ||
             rv == VP8_STATUS_BITSTREAM_ERROR) {
    PostDataError();
    return;
  } else if (rv == VP8_STATUS_UNSUPPORTED_FEATURE ||
             rv == VP8_STATUS_USER_ABORT) {
    PostDecoderError(NS_ERROR_FAILURE);
    return;
  }

  // Catch any remaining erroneous return value.
  if (rv != VP8_STATUS_OK && rv != VP8_STATUS_SUSPENDED) {
    PostDecoderError(NS_ERROR_FAILURE);
    return;
  }

  int lastLineRead = -1;
  int width = 0;
  int height = 0;
  int stride = 0;

  const uint8_t* data =
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
    PostDecoderError(NS_ERROR_FAILURE);
    return;
  }

  if (lastLineRead > mLastLine) {
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
  }
}

} // namespace image
} // namespace mozilla
