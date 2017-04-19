/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "nsBidiKeyboard.h"
#include "nsCocoaUtils.h"
#include "TextInputHandler.h"

// This must be the last include:
#include "nsObjCExceptions.h"

using namespace mozilla::widget;

NS_IMPL_ISUPPORTS(nsBidiKeyboard, nsIBidiKeyboard)

nsBidiKeyboard::nsBidiKeyboard() : nsIBidiKeyboard()
{
  Reset();
}

nsBidiKeyboard::~nsBidiKeyboard()
{
}

NS_IMETHODIMP nsBidiKeyboard::Reset()
{
  return NS_OK;
}

NS_IMETHODIMP nsBidiKeyboard::IsLangRTL(bool *aIsRTL)
{
#if(0)
  *aIsRTL = TISInputSourceWrapper::CurrentInputSource().IsForRTLLanguage();
  return NS_OK;
#else
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  *aIsRTL = false;
  nsresult rv = NS_ERROR_FAILURE;

  OSStatus err;
  KeyboardLayoutRef currentKeyboard;

  err = ::KLGetCurrentKeyboardLayout(&currentKeyboard);
  if (err == noErr) {
    const void* currentKeyboardResID;
    err = ::KLGetKeyboardLayoutProperty(currentKeyboard, kKLIdentifier,
                                        &currentKeyboardResID);
    if (err == noErr) {
      // Check if the resource id is BiDi associated (Arabic, Persian, Hebrew)
      // (Persian is included in the Arabic range)
      // http://developer.apple.com/documentation/mac/Text/Text-534.html#HEADING534-0
      // Note: these ^^ values are negative on Mac OS X
      *aIsRTL = ((SInt32)currentKeyboardResID >= -18943 &&
                 (SInt32)currentKeyboardResID <= -17920);
      rv = NS_OK;
    }
  }

  return rv;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
#endif
}

NS_IMETHODIMP nsBidiKeyboard::GetHaveBidiKeyboards(bool* aResult)
{
  // not implemented yet
  return NS_ERROR_NOT_IMPLEMENTED;
}
