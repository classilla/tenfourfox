/* -*- Mode: C++; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim: set ts=8 sts=2 et sw=2 tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef mozilla_dom_DatePickerParent_h
#define mozilla_dom_DatePickerParent_h

#include "mozilla/dom/PDatePickerParent.h"
#include "nsIDatePicker.h"

namespace mozilla {
namespace dom {

class DatePickerParent : public PDatePickerParent
{
 public:
  DatePickerParent(const nsString& aTitle)
  : mTitle(aTitle)
  {}

  virtual bool RecvOpen() override;
  virtual void ActorDestroy(ActorDestroyReason aWhy) override;

  void Done(int16_t aResult);

  class DatePickerShownCallback final
    : public nsIDatePickerShownCallback
  {
  public:
    explicit DatePickerShownCallback(DatePickerParent* aDatePickerParent)
      : mDatePickerParent(aDatePickerParent)
    {}

    NS_DECL_ISUPPORTS
    NS_DECL_NSIDATEPICKERSHOWNCALLBACK

    NS_IMETHODIMP Update(const nsAString& aDate);

    void Destroy();

  private:
    ~DatePickerShownCallback() {}

    DatePickerParent* mDatePickerParent;
  };

 private:
  virtual ~DatePickerParent() {}

  bool CreateDatePicker();

  RefPtr<DatePickerShownCallback> mCallback;
  nsCOMPtr<nsIDatePicker> mPicker;

  nsString mTitle;
};

} // namespace dom
} // namespace mozilla

#endif // mozilla_dom_DatePickerParent_h
