/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim:set ts=2 sw=2 sts=2 et cindent: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef mozilla_MiniMP3Module_h
#define mozilla_MiniMP3Module_h

#include "PlatformDecoderModule.h"

namespace mozilla {

class MiniMP3Module : public PlatformDecoderModule {
public:
  MiniMP3Module();
  virtual ~MiniMP3Module();
  
  nsresult Startup() override;

  // Decode thread.
  already_AddRefed<MediaDataDecoder>
  CreateVideoDecoder(const VideoInfo& aConfig,
                     layers::LayersBackend aLayersBackend,
                     layers::ImageContainer* aImageContainer,
                     FlushableTaskQueue* aVideoTaskQueue,
                     MediaDataDecoderCallback* aCallback) override;

  // Decode thread.
  already_AddRefed<MediaDataDecoder>
  CreateAudioDecoder(const AudioInfo& aConfig,
                     FlushableTaskQueue* aAudioTaskQueue,
                     MediaDataDecoderCallback* aCallback) override;

  bool SupportsMimeType(const nsACString& aMimeType) const override;

  ConversionRequired
  DecoderNeedsConversion(const TrackInfo& aConfig) const override;

};

} // namespace mozilla

#endif // mozilla_MiniMP3Module_h
