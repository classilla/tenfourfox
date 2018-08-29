/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef nsTimePicker_h_
#define nsTimePicker_h_

#include "nsBaseTimePicker.h"

class nsTimePicker : public nsBaseTimePicker
{
public:
  nsTimePicker();

  NS_DECL_ISUPPORTS

  // nsITimePicker (less what's in nsBaseTimePicker)
  NS_IMETHOD Show(int16_t *_retval) override;
  NS_IMETHOD GetDefaultTime(nsAString &aDefaultTime) override;
  NS_IMETHOD SetDefaultTime(const nsAString &aDefaultTime) override;
  NS_IMETHOD GetMinTime(nsAString &aMinTime) override;
  NS_IMETHOD SetMinTime(const nsAString &aMinTime) override;
  NS_IMETHOD GetMaxTime(nsAString &aMaxTime) override;
  NS_IMETHOD SetMaxTime(const nsAString &aMaxTime) override;
  NS_IMETHOD GetStep(double *aStep) override;
  NS_IMETHOD SetStep(const double aStep) override;
  NS_IMETHOD GetSelectedTime(nsAString &aSelectedTime);

protected:
  virtual ~nsTimePicker();

  virtual void InitNative(nsIWidget *aParent, const nsAString& aTitle) override;

  int16_t GetTime();

  // Native control controls
  void    SetDialogTitle(const nsString& inTitle, id aDialog);

  nsString               mTitle;
  nsString               mTime;
  bool                   mHasDefault;
  nsString               mDefault;
  nsString               mMinTime;
  bool                   mHasMin;
  nsString               mMaxTime;
  bool                   mHasMax;
  double                 mStep;
};

#endif // nsTimePicker_h_
