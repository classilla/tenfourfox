/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef nsBaseTimePicker_h__
#define nsBaseTimePicker_h__

#include "nsISupports.h"
#include "nsITimePicker.h"
#include "nsCOMPtr.h"
#include "nsString.h"
#include "nsIWidget.h"

class nsPIDOMWindow;
class nsIWidget;

class nsBaseTimePicker : public nsITimePicker
{
public:
  nsBaseTimePicker();
  virtual ~nsBaseTimePicker();

  NS_IMETHOD Init(nsIDOMWindow *aParent,
                  const nsAString& aTitle);

  NS_IMETHOD Open(nsITimePickerShownCallback *aCallback);

protected:
  virtual void InitNative(nsIWidget *aParent, const nsAString& aTitle) = 0;

  // This is an innerWindow.
  nsCOMPtr<nsPIDOMWindow> mParent;
};

#endif // nsBaseTimePicker_h__
