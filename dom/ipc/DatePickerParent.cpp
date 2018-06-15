/* -*- Mode: C++; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim: set ts=8 sts=2 et sw=2 tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "DatePickerParent.h"
#include "nsComponentManagerUtils.h"
#include "nsIDocument.h"
#include "nsIDOMWindow.h"
#include "mozilla/unused.h"
#include "mozilla/dom/Element.h"
#include "mozilla/dom/TabParent.h"

using mozilla::Unused;
using namespace mozilla::dom;

NS_IMPL_ISUPPORTS(DatePickerParent::DatePickerShownCallback,
                  nsIDatePickerShownCallback);

NS_IMETHODIMP
DatePickerParent::DatePickerShownCallback::Update(const nsAString& aDate)
{
  if (mDatePickerParent) {
    Unused << mDatePickerParent->SendUpdate(nsString(aDate));
  }
  return NS_OK;
}

NS_IMETHODIMP
DatePickerParent::DatePickerShownCallback::Done(int16_t aResult)
{
  if (mDatePickerParent) {
    mDatePickerParent->Done(aResult);
  }
  return NS_OK;
}

void
DatePickerParent::DatePickerShownCallback::Destroy()
{
  mDatePickerParent = nullptr;
}

bool
DatePickerParent::CreateDatePicker()
{
  mPicker = do_CreateInstance("@mozilla.org/datepicker;1");
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
DatePickerParent::Done(int16_t aResult)
{
   Unused << Send__delete__(this, nsString());
   MOZ_CRASH("DatePickerParent::Done NYI");
}

bool
DatePickerParent::RecvOpen()
{
  if (!CreateDatePicker()) {
    Unused << Send__delete__(this, nsString());
    return true;
  }

  mCallback = new DatePickerShownCallback(this);

  mPicker->Open(mCallback);
  return true;
};

void
DatePickerParent::ActorDestroy(ActorDestroyReason aWhy)
{
  if (mCallback) {
    mCallback->Destroy();
  }
}
