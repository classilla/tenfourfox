/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim:set ts=2 sw=2 sts=2 et cindent: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef mozilla_MiniMP3Decoder_h
#define mozilla_MiniMP3Decoder_h

#include "PlatformDecoderModule.h"
#include "mozilla/ReentrantMonitor.h"
#include "mozilla/Vector.h"
#include "nsIThread.h"

/* relevant bits from minimp3 */

#define MP3_FRAME_SIZE 1152
#define MP3_MAX_CODED_FRAME_SIZE 1792
#define MP3_MAX_CHANNELS 2
#define MAXIMUM_ALLOWABLE_FRAME_SIZE 524288
#define SBLIMIT 32

#define MP3_STEREO  0
#define MP3_JSTEREO 1
#define MP3_DUAL    2
#define MP3_MONO    3

#define HEADER_SIZE 4
#define BACKSTEP_SIZE 512
#define EXTRABYTES 24

#define VLC_TYPE int16_t

#define MP3_MAX_SAMPLES_PER_FRAME (1152*2)
#define TABLE_4_3_SIZE (8191 + 16)*4

struct bitstream_t {
    const uint8_t *buffer, *buffer_end;
    int index;
    int size_in_bits;
};

typedef void* mp3_decoder_t;

struct mp3_info_t {
    int sample_rate;
    int channels;
    int audio_bytes;  // generated amount of audio per frame
};

struct mp3_context_t {
    uint8_t last_buf[2*BACKSTEP_SIZE + EXTRABYTES];
    int last_buf_size;
    int frame_size;
    uint32_t free_format_next_header;
    int error_protection;
    int sample_rate;
    int sample_rate_index;
    int bit_rate;
    bitstream_t gb;
    bitstream_t in_gb;
    int nb_channels;
    int mode;
    int mode_ext;
    int lsf;
    int16_t synth_buf[MP3_MAX_CHANNELS][512 * 2];
    int synth_buf_offset[MP3_MAX_CHANNELS];
    int32_t sb_samples[MP3_MAX_CHANNELS][36][SBLIMIT];
    int32_t mdct_buf[MP3_MAX_CHANNELS][SBLIMIT * 18];
    int dither_state;
};

extern "C" int mp3_init(mp3_context_t *dec);
extern "C" int mp3_close(mp3_context_t *dec);
extern "C" int mp3_decode(mp3_context_t *dec, void *buf, int bytes,
	signed short *out, mp3_info_t *info);

namespace mozilla {

class FlushableTaskQueue;
class MediaDataDecoderCallback;

class MiniMP3Decoder : public MediaDataDecoder {
public:
  MiniMP3Decoder(const AudioInfo& aConfig,
                 FlushableTaskQueue* aVideoTaskQueue,
                 MediaDataDecoderCallback* aCallback);
  virtual ~MiniMP3Decoder();

  RefPtr<InitPromise> Init() override;
  nsresult Input(MediaRawData* aSample) override;
  nsresult Flush() override;
  nsresult Drain() override;
  nsresult Shutdown() override;

private:
  mp3_info_t mMP3Info;
  mp3_context_t mMP3Decoder;
  RefPtr<FlushableTaskQueue> mTaskQueue;
  MediaDataDecoderCallback* mCallback;

  void DecodePacket(MediaRawData* aSample);
};

} // namespace mozilla

#endif // mozilla_MiniMP3Decoder_h
