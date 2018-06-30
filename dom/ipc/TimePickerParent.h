/* -*- Mode: C++; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim: set ts=8 sts=2 et sw=2 tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef mozilla_dom_TimePickerParent_h
#define mozilla_dom_TimePickerParent_h

#include "mozilla/dom/PTimePickerParent.h"
#include "nsITimePicker.h"

namespace mozilla {
namespace dom {

class TimePickerParent : public PTimePickerParent
{
 public:
  TimePickerParent(const nsString& aTitle)
  : mTitle(aTitle)
  {}

  virtual bool RecvOpen() override;
  virtual void ActorDestroy(ActorDestroyReason aWhy) override;

  void Done(int16_t aResult);

  class TimePickerShownCallback final
    : public nsITimePickerShownCallback
  {
  public:
    explicit TimePickerShownCallback(TimePickerParent* aTimePickerParent)
      : mTimePickerParent(aTimePickerParent)
    {}

    NS_DECL_ISUPPORTS
    NS_DECL_NSIDATEPICKERSHOWNCALLBACK

    NS_IMETHODIMP Update(const nsAString& aTime);

    void Destroy();

  private:
    ~TimePickerShownCallback() {}

    TimePickerParent* mTimePickerParent;
  };

 private:
  virtual ~TimePickerParent() {}

  bool CreateTimePicker();

  RefPtr<TimePickerShownCallback> mCallback;
  nsCOMPtr<nsITimePicker> mPicker;

  nsString mTitle;
};

} // namespace dom
} // namespace mozilla

#endif // mozilla_dom_TimePickerParent_h
