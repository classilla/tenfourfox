/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef nsBaseDatePicker_h__
#define nsBaseDatePicker_h__

#include "nsISupports.h"
#include "nsIDatePicker.h"
#include "nsCOMPtr.h"
#include "nsString.h"
#include "nsIWidget.h"

class nsPIDOMWindow;
class nsIWidget;

class nsBaseDatePicker : public nsIDatePicker
{
public:
  nsBaseDatePicker();
  virtual ~nsBaseDatePicker();

  NS_IMETHOD Init(nsIDOMWindow *aParent,
                  const nsAString& aTitle);

  NS_IMETHOD Open(nsIDatePickerShownCallback *aCallback);

protected:
  virtual void InitNative(nsIWidget *aParent, const nsAString& aTitle) = 0;

  // This is an innerWindow.
  nsCOMPtr<nsPIDOMWindow> mParent;
};

#endif // nsBaseDatePicker_h__
