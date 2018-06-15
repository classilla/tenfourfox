/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2 -*-
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "nsDatePickerProxy.h"
#include "nsComponentManagerUtils.h"
#include "mozilla/dom/TabChild.h"

using namespace mozilla::dom;

NS_IMPL_ISUPPORTS(nsDatePickerProxy, nsIDatePicker)

nsDatePickerProxy::nsDatePickerProxy()
{
}

nsDatePickerProxy::~nsDatePickerProxy()
{
}

NS_IMETHODIMP
nsDatePickerProxy::Init(nsIDOMWindow* aParent, const nsAString& aTitle)
{
  TabChild* tabChild = TabChild::GetFrom(aParent);
  if (!tabChild) {
    return NS_ERROR_FAILURE;
  }

  MOZ_CRASH("Date picker not implemented for e10s");

  mParent = do_QueryInterface(aParent);
  if (!mParent->IsInnerWindow()) {
    mParent = mParent->GetCurrentInnerWindow();
  }

  NS_ADDREF_THIS();
  tabChild->SendPDatePickerConstructor(nsString(aTitle));
  return NS_OK;
}

void
nsDatePickerProxy::InitNative(nsIWidget* aParent, const nsAString& aTitle)
{
}

NS_IMETHODIMP
nsDatePickerProxy::Open(nsIDatePickerShownCallback* aCallback)
{
  mCallback = aCallback;

  return NS_ERROR_FAILURE;
}

NS_IMETHODIMP
nsDatePickerProxy::Show(int16_t* aReturn)
{
  MOZ_ASSERT(false, "Show is unimplemented; use Open");
  return NS_ERROR_NOT_IMPLEMENTED;
}

NS_IMETHODIMP nsDatePickerProxy::GetDefaultDate(nsAString &aDefaultDate) {return NS_ERROR_NOT_IMPLEMENTED;}
NS_IMETHODIMP nsDatePickerProxy::SetDefaultDate(const nsAString &aDefaultDate) {return NS_ERROR_NOT_IMPLEMENTED;}
NS_IMETHODIMP nsDatePickerProxy::GetMinDate(nsAString &aMinDate) {return NS_ERROR_NOT_IMPLEMENTED;}
NS_IMETHODIMP nsDatePickerProxy::SetMinDate(const nsAString &aMinDate) {return NS_ERROR_NOT_IMPLEMENTED;}
NS_IMETHODIMP nsDatePickerProxy::GetMaxDate(nsAString &aMaxDate) {return NS_ERROR_NOT_IMPLEMENTED;};
NS_IMETHODIMP nsDatePickerProxy::SetMaxDate(const nsAString &aMaxDate) {return NS_ERROR_NOT_IMPLEMENTED;}
NS_IMETHODIMP nsDatePickerProxy::GetSelectedDate(nsAString &aSelectedDate) {return NS_ERROR_NOT_IMPLEMENTED;}

bool
nsDatePickerProxy::Recv__delete__(const nsString& date, const int16_t& aResult)
{
  if (mCallback) {
    mCallback->Done(aResult);
    mCallback = nullptr;
  }

  return true;
}

bool
nsDatePickerProxy::RecvUpdate(const nsString& date)
{
  MOZ_CRASH("unimplemented");
  return false;
}
