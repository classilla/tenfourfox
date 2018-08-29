/* -*- Mode: C++; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim: set ts=8 sts=2 et sw=2 tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "TimePickerParent.h"
#include "nsComponentManagerUtils.h"
#include "nsIDocument.h"
#include "nsIDOMWindow.h"
#include "mozilla/unused.h"
#include "mozilla/dom/Element.h"
#include "mozilla/dom/TabParent.h"

using mozilla::Unused;
using namespace mozilla::dom;

NS_IMPL_ISUPPORTS(TimePickerParent::TimePickerShownCallback,
                  nsITimePickerShownCallback);

NS_IMETHODIMP
TimePickerParent::TimePickerShownCallback::Update(const nsAString& aTime)
{
  if (mTimePickerParent) {
    Unused << mTimePickerParent->SendUpdate(nsString(aTime));
  }
  return NS_OK;
}

NS_IMETHODIMP
TimePickerParent::TimePickerShownCallback::Done(int16_t aResult)
{
  if (mTimePickerParent) {
    mTimePickerParent->Done(aResult);
  }
  return NS_OK;
}

void
TimePickerParent::TimePickerShownCallback::Destroy()
{
  mTimePickerParent = nullptr;
}

bool
TimePickerParent::CreateTimePicker()
{
  mPicker = do_CreateInstance("@mozilla.org/timepicker;1");
  if (!mPicker) {
    return false;
  }

  Element* ownerElement = TabParent::GetFrom(Manager())->GetOwnerElement();
  if (!ownerElement) {
    return false;
  }

  nsCOMPtr<nsIDOMWindow> window = do_QueryInterface(ownerElement->OwnerDoc()->GetWindow());
  if (!window) {
    return false;
  }

  return NS_SUCCEEDED(mPicker->Init(window, mTitle));
}

void
TimePickerParent::Done(int16_t aResult)
{
   Unused << Send__delete__(this, nsString());
   MOZ_CRASH("TimePickerParent::Done NYI");
}

bool
TimePickerParent::RecvOpen()
{
  if (!CreateTimePicker()) {
    Unused << Send__delete__(this, nsString());
    return true;
  }

  mCallback = new TimePickerShownCallback(this);

  mPicker->Open(mCallback);
  return true;
};

void
TimePickerParent::ActorDestroy(ActorDestroyReason aWhy)
{
  if (mCallback) {
    mCallback->Destroy();
  }
}
