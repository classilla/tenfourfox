/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef nsDatePicker_h_
#define nsDatePicker_h_

#include "nsBaseDatePicker.h"

class nsDatePicker : public nsBaseDatePicker
{
public:
  nsDatePicker(); 

  NS_DECL_ISUPPORTS

  // nsIDatePicker (less what's in nsBaseDatePicker)
  NS_IMETHOD Show(int16_t *_retval) override;
  NS_IMETHOD GetDefaultDate(nsAString &aDefaultDate) override;
  NS_IMETHOD SetDefaultDate(const nsAString &aDefaultDate) override;
  NS_IMETHOD GetMinDate(nsAString &aMinDate) override;
  NS_IMETHOD SetMinDate(const nsAString &aMinDate) override;
  NS_IMETHOD GetMaxDate(nsAString &aMaxDate) override;
  NS_IMETHOD SetMaxDate(const nsAString &aMaxDate) override;
  NS_IMETHOD GetSelectedDate(nsAString &aSelectedDate);

protected:
  virtual ~nsDatePicker();

  virtual void InitNative(nsIWidget *aParent, const nsAString& aTitle) override;

  int16_t GetDate();

  // Native control controls
  void    SetDialogTitle(const nsString& inTitle, id aDialog);

  nsString               mTitle;
  nsString               mDate;
  bool                   mHasDefault;
  nsString               mDefault;
  nsString               mMinDate;
  nsString               mMaxDate;
};

#endif // nsDatePicker_h_
