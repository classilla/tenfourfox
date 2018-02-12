/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "nsCOMPtr.h"
#include "nsPIDOMWindow.h"
#include "nsIDocShell.h"
#include "nsIInterfaceRequestorUtils.h"
#include "nsIBaseWindow.h"
#include "nsIWidget.h"

#include "nsXPIDLString.h"
#include "nsIServiceManager.h"
#include "nsCOMArray.h"
#include "nsEnumeratorUtils.h"
#include "mozilla/Services.h"
#include "WidgetUtils.h"
#include "nsThreadUtils.h"

#include "nsBaseDatePicker.h"

using namespace mozilla::widget;
using namespace mozilla::dom;

/**
 * A runnable to dispatch from the main thread to the main thread to display
 * the date picker while letting the showAsync method return right away.
*/
class AsyncShowDatePicker : public nsRunnable
{
public:
  AsyncShowDatePicker(nsIDatePicker *aDatePicker,
                      nsIDatePickerShownCallback *aCallback) :
    mDatePicker(aDatePicker),
    mCallback(aCallback)
  {
  }

  NS_IMETHOD Run()
  {
    NS_ASSERTION(NS_IsMainThread(),
                 "AsyncShowDatePicker should be on the main thread!");

    // It's possible that some widget implementations require GUI operations
    // to be on the main thread, so that's why we're not dispatching to another
    // thread and calling back to the main after it's done.
    int16_t result = nsIDatePicker::returnCancel;
    nsresult rv = mDatePicker->Show(&result);
    if (NS_FAILED(rv)) {
      NS_ERROR("DatePicker's Show() implementation failed!");
    }

    if (mCallback) {
      mCallback->Done(result);
    }
    return NS_OK;
  }

private:
  RefPtr<nsIDatePicker> mDatePicker;
  RefPtr<nsIDatePickerShownCallback> mCallback;
};

nsBaseDatePicker::nsBaseDatePicker()
{
}

nsBaseDatePicker::~nsBaseDatePicker()
{
}

NS_IMETHODIMP nsBaseDatePicker::Init(nsIDOMWindow *aParent,
                                     const nsAString& aTitle)
{
  NS_PRECONDITION(aParent, "Null parent passed to datepicker, no date "
                  "picker for you!");
  nsCOMPtr<nsIWidget> widget = WidgetUtils::DOMWindowToWidget(aParent);
  NS_ENSURE_TRUE(widget, NS_ERROR_FAILURE);

  mParent = do_QueryInterface(aParent);
  if (!mParent->IsInnerWindow()) {
    mParent = mParent->GetCurrentInnerWindow();
  }

  InitNative(widget, aTitle);

  return NS_OK;
}

NS_IMETHODIMP
nsBaseDatePicker::Open(nsIDatePickerShownCallback *aCallback)
{
  nsCOMPtr<nsIRunnable> filePickerEvent =
    new AsyncShowDatePicker(this, aCallback);
  return NS_DispatchToMainThread(filePickerEvent);
}