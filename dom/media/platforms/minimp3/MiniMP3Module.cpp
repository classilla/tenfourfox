/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim:set ts=2 sw=2 sts=2 et cindent: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "MiniMP3Decoder.h"
#include "MiniMP3Module.h"
#include "mozilla/Preferences.h"
#include "mozilla/DebugOnly.h"
#include "mozilla/Logging.h"

namespace mozilla {

MiniMP3Module::MiniMP3Module()
{
}

MiniMP3Module::~MiniMP3Module()
{
}

nsresult
MiniMP3Module::Startup()
{ return NS_OK; }

already_AddRefed<MediaDataDecoder>
MiniMP3Module::CreateVideoDecoder(const VideoInfo& aConfig,
                                       layers::LayersBackend aLayersBackend,
                                       layers::ImageContainer* aImageContainer,
                                       FlushableTaskQueue* aVideoTaskQueue,
                                       MediaDataDecoderCallback* aCallback)
{
  MOZ_ASSERT(0, "MiniMP3Module doesn't create video decoders!!");
  return nullptr;
}

already_AddRefed<MediaDataDecoder>
MiniMP3Module::CreateAudioDecoder(const AudioInfo& aConfig,
                                       FlushableTaskQueue* aAudioTaskQueue,
                                       MediaDataDecoderCallback* aCallback)
{
  RefPtr<MediaDataDecoder> decoder =
    new MiniMP3Decoder(aConfig, aAudioTaskQueue, aCallback);
  return decoder.forget();
}

bool
MiniMP3Module::SupportsMimeType(const nsACString& aMimeType) const
{
#if DEBUG
fprintf(stderr, "MiniMP3: SupportsMimeType: %i\n", (aMimeType.EqualsLiteral("audio/mpeg")));
#endif
  return (aMimeType.EqualsLiteral("audio/mpeg"));
}

PlatformDecoderModule::ConversionRequired
MiniMP3Module::DecoderNeedsConversion(const TrackInfo& aConfig) const
{
  return kNeedNone;
}

} // namespace mozilla
