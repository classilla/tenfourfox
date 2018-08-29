/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2 -*-
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "nsTimePickerProxy.h"
#include "nsComponentManagerUtils.h"
#include "mozilla/dom/TabChild.h"

using namespace mozilla::dom;

NS_IMPL_ISUPPORTS(nsTimePickerProxy, nsITimePicker)

nsTimePickerProxy::nsTimePickerProxy()
{
}

nsTimePickerProxy::~nsTimePickerProxy()
{
}

NS_IMETHODIMP
nsTimePickerProxy::Init(nsIDOMWindow* aParent, const nsAString& aTitle)
{
  TabChild* tabChild = TabChild::GetFrom(aParent);
  if (!tabChild) {
    return NS_ERROR_FAILURE;
  }

  MOZ_CRASH("Time picker not implemented for e10s");

  mParent = do_QueryInterface(aParent);
  if (!mParent->IsInnerWindow()) {
    mParent = mParent->GetCurrentInnerWindow();
  }

  NS_ADDREF_THIS();
  tabChild->SendPTimePickerConstructor(nsString(aTitle));
  return NS_OK;
}

void
nsTimePickerProxy::InitNative(nsIWidget* aParent, const nsAString& aTitle)
{
}

NS_IMETHODIMP
nsTimePickerProxy::Open(nsITimePickerShownCallback* aCallback)
{
  mCallback = aCallback;

  return NS_ERROR_FAILURE;
}

NS_IMETHODIMP
nsTimePickerProxy::Show(int16_t* aReturn)
{
  MOZ_ASSERT(false, "Show is unimplemented; use Open");
  return NS_ERROR_NOT_IMPLEMENTED;
}

NS_IMETHODIMP nsTimePickerProxy::GetDefaultTime(nsAString &aDefaultTime) {return NS_ERROR_NOT_IMPLEMENTED;}
NS_IMETHODIMP nsTimePickerProxy::SetDefaultTime(const nsAString &aDefaultTime) {return NS_ERROR_NOT_IMPLEMENTED;}
NS_IMETHODIMP nsTimePickerProxy::GetMinTime(nsAString &aMinTime) {return NS_ERROR_NOT_IMPLEMENTED;}
NS_IMETHODIMP nsTimePickerProxy::SetMinTime(const nsAString &aMinTime) {return NS_ERROR_NOT_IMPLEMENTED;}
NS_IMETHODIMP nsTimePickerProxy::GetMaxTime(nsAString &aMaxTime) {return NS_ERROR_NOT_IMPLEMENTED;};
NS_IMETHODIMP nsTimePickerProxy::SetMaxTime(const nsAString &aMaxTime) {return NS_ERROR_NOT_IMPLEMENTED;}
NS_IMETHODIMP nsTimePickerProxy::GetStep(double *aStep) {return NS_ERROR_NOT_IMPLEMENTED;}
NS_IMETHODIMP nsTimePickerProxy::SetStep(const double aStep) {return NS_ERROR_NOT_IMPLEMENTED;}
NS_IMETHODIMP nsTimePickerProxy::GetSelectedTime(nsAString &aSelectedTime) {return NS_ERROR_NOT_IMPLEMENTED;}

bool
nsTimePickerProxy::Recv__delete__(const nsString& time, const int16_t& aResult)
{
  if (mCallback) {
    mCallback->Done(aResult);
    mCallback = nullptr;
  }

  return true;
}

bool
nsTimePickerProxy::RecvUpdate(const nsString& time)
{
  MOZ_CRASH("unimplemented");
  return false;
}
