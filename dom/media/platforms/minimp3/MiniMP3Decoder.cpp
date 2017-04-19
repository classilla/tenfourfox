/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim:set ts=2 sw=2 sts=2 et cindent: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* MiniMP3 platform decoder
   (C)2016 Cameron Kaiser */
   
#include "MediaInfo.h"
#include "MiniMP3Decoder.h"
#include "mozilla/Logging.h"
#include "mozilla/UniquePtr.h"

extern mozilla::LogModule* GetPDMLog();
#define LOG(...) MOZ_LOG(GetPDMLog(), mozilla::LogLevel::Debug, (__VA_ARGS__))

namespace mozilla {

MiniMP3Decoder::MiniMP3Decoder(const AudioInfo& aConfig,
                               FlushableTaskQueue* aAudioTaskQueue,
                               MediaDataDecoderCallback* aCallback)
  : mTaskQueue(aAudioTaskQueue)
  , mCallback(aCallback)
{
#if defined(MOZ_SAMPLE_TYPE_FLOAT32)
#else
#error Unknown audio sample type
#endif

#if DEBUG
  fprintf(stderr, "MiniMP3Decoder::MiniMP3Decoder\n");
#endif
  MOZ_COUNT_CTOR(MiniMP3Decoder);
}

MiniMP3Decoder::~MiniMP3Decoder()
{
  MOZ_COUNT_DTOR(MiniMP3Decoder);
}

RefPtr<MediaDataDecoder::InitPromise>
MiniMP3Decoder::Init()
{
  int rv = mp3_init(&mMP3Decoder);
#if DEBUG
  fprintf(stderr, "mp3_init(%i)\n", rv);
#endif
  if (rv) {
    return InitPromise::CreateAndReject(DecoderFailureReason::INIT_ERROR, __func__);
  }

  return InitPromise::CreateAndResolve(TrackType::kAudioTrack, __func__);
}

nsresult
MiniMP3Decoder::Input(MediaRawData* aSample)
{
/*
  nsCOMPtr<nsIRunnable> runnable =
      NS_NewRunnableMethodWithArg<RefPtr<MediaRawData>>(
        this,
        &MiniMP3Decoder::DecodePacket,
        RefPtr<MediaRawData>(aSample));
  mTaskQueue->Dispatch(runnable.forget());
*/

  // MiniMP3 is probably not threadsafe, so ...
  // TaskQueue code left in case I replace it with something else later.
  DecodePacket(aSample);
  return NS_OK;
}

nsresult
MiniMP3Decoder::Flush()
{
  LOG("Flushing MiniMP3 decoder");
  mTaskQueue->Flush();
#if DEBUG
  fprintf(stderr, "FLUSHING: mp3_close()\n");
#endif
  mp3_close(&mMP3Decoder);
  int rv = mp3_init(&mMP3Decoder);
#if DEBUG
  fprintf(stderr, "FLUSHING: mp3_init(%i)\n", rv);
#endif
  if (rv) {
    LOG("Error %d resetting minimp3", rv);
    return NS_ERROR_FAILURE;
  }
  return NS_OK;
}

nsresult
MiniMP3Decoder::Drain()
{
  LOG("Draining MiniMP3 decoder");
  mTaskQueue->AwaitIdle();
  mCallback->DrainComplete();
  return Flush();
}

nsresult
MiniMP3Decoder::Shutdown()
{
  LOG("Shutdown: MiniMP3 decoder");
#if DEBUG
  fprintf(stderr, "CLOSING: mp3_close()\n");
#endif
  mp3_close(&mMP3Decoder);
  return NS_OK;
}

void
MiniMP3Decoder::DecodePacket(MediaRawData* aSample)
{
  //MOZ_ASSERT(mTaskQueue->IsCurrentThreadIn());
  
  signed short samplebuf[(1152*2)];
  size_t frameSize = mp3_decode(&mMP3Decoder, (void *)(aSample->Data()),
  	aSample->Size(), samplebuf, &mMP3Info);
  if (!frameSize || mMP3Info.audio_bytes < 0 || mMP3Info.audio_bytes > 1152*2*2 ||
      mMP3Info.channels < 1 || mMP3Info.channels > 2) {
#if DEBUG
	fprintf(stderr, "decode failure frameSize=%i audio_bytes=%i\n", frameSize, mMP3Info.audio_bytes);
#endif
    // Throwing an error generally whacks the playback controller and
    // some MP3 encoders may make variant frames, so see if we can avoid
    // embracing permanent failure when it might just be temporary.
    if (!frameSize) mCallback->Error();
    
    // We got a frame size, it just didn't like it. See if the next frame is better.
    // (Might not have had audio?)
	return;
  }

  size_t cframes = mMP3Info.audio_bytes / 2;
  size_t frames = cframes / mMP3Info.channels;

  // Essentially do as the WaveReader does, except we know that we have
  // native endian shorts, so our job is a little simpler.
  auto sampleBuffer = MakeUnique<AudioDataValue[]>(cframes);
  AudioDataValue *s = sampleBuffer.get();

  if (MOZ_LIKELY((mMP3Info.audio_bytes & 1) == 0)) {
	if (MOZ_LIKELY((mMP3Info.audio_bytes & 3) == 0)) {
		// Unroll the loop even more.
  		for (size_t i=0; i < cframes; i++) {
			*s++ = samplebuf[i++]/32768.0f;
			*s++ = samplebuf[i++]/32768.0f;
			*s++ = samplebuf[i++]/32768.0f;
			*s++ = samplebuf[i]/32768.0f;
		}
	} else {
		// Unroll the loop.
  		for (size_t i=0; i < cframes; i++) {
			*s++ = samplebuf[i++]/32768.0f;
			*s++ = samplebuf[i]/32768.0f;
		}
	}
  } else {
	// Don't unroll the loop.
  	for (size_t i=0; i < cframes; i++) { *s++ = samplebuf[i]/32768.0f; }
  }

  media::TimeUnit duration = FramesToTimeUnit(frames, mMP3Info.sample_rate);
  if (!duration.IsValid()) {
    NS_WARNING("Invalid count of accumulated audio samples");
    // mCallback->Error(); /* ??? */
    return;
  }

#ifdef LOG_SAMPLE_DECODE
  LOG("pushed audio at time %lfs; duration %lfs\n",
      (double)aSample->mTime / USECS_PER_S,
      duration.ToSeconds());
#endif

  RefPtr<AudioData> audio = new AudioData(aSample->mOffset,
                                          aSample->mTime,
                                          duration.ToMicroseconds(),
                                          frames,
                                          Move(sampleBuffer),
                                          mMP3Info.channels,
                                          mMP3Info.sample_rate);
  mCallback->Output(audio);
  return;
}


} // namespace mozilla
