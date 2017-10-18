/* -*- Mode: C++; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim: set ts=8 sts=2 et sw=2 tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef nsIContentInlines_h
#define nsIContentInlines_h

#include "nsIContent.h"
#include "nsIDocument.h"
#include "nsContentUtils.h"
#include "nsIFrame.h"

inline bool
nsIContent::IsInHTMLDocument() const
{
  return OwnerDoc()->IsHTMLDocument();
}

inline void
nsIContent::SetPrimaryFrame(nsIFrame* aFrame)
{
  MOZ_ASSERT(IsInUncomposedDoc() || IsInShadowTree(), "This will end badly!");
  NS_PRECONDITION(!aFrame || !mPrimaryFrame || aFrame == mPrimaryFrame,
                  "Losing track of existing primary frame");

  if (aFrame) {
    aFrame->SetIsPrimaryFrame(true);
  } else if (nsIFrame* currentPrimaryFrame = GetPrimaryFrame()) {
    currentPrimaryFrame->SetIsPrimaryFrame(false);
  }

  mPrimaryFrame = aFrame;
}

#endif // nsIContentInlines_h
