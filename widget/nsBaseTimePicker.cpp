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

#include "nsBaseTimePicker.h"

using namespace mozilla::widget;
using namespace mozilla::dom;

/**
 * A runnable to dispatch from the main thread to the main thread to display
 * the time picker while letting the showAsync method return right away.
*/
class AsyncShowTimePicker : public nsRunnable
{
public:
  AsyncShowTimePicker(nsITimePicker *aTimePicker,
                      nsITimePickerShownCallback *aCallback) :
    mTimePicker(aTimePicker),
    mCallback(aCallback)
  {
  }

  NS_IMETHOD Run()
  {
    NS_ASSERTION(NS_IsMainThread(),
                 "AsyncShowTimePicker should be on the main thread!");

    // It's possible that some widget implementations require GUI operations
    // to be on the main thread, so that's why we're not dispatching to another
    // thread and calling back to the main after it's done.
    int16_t result = nsITimePicker::returnCancel;
    nsresult rv = mTimePicker->Show(&result);
    if (NS_FAILED(rv)) {
      NS_ERROR("TimePicker's Show() implementation failed!");
    }

    if (mCallback) {
      mCallback->Done(result);
    }
    return NS_OK;
  }

private:
  RefPtr<nsITimePicker> mTimePicker;
  RefPtr<nsITimePickerShownCallback> mCallback;
};

nsBaseTimePicker::nsBaseTimePicker()
{
}

nsBaseTimePicker::~nsBaseTimePicker()
{
}

NS_IMETHODIMP nsBaseTimePicker::Init(nsIDOMWindow *aParent,
                                     const nsAString& aTitle)
{
  NS_PRECONDITION(aParent, "Null parent passed to timepicker, no time "
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
nsBaseTimePicker::Open(nsITimePickerShownCallback *aCallback)
{
  nsCOMPtr<nsIRunnable> filePickerEvent =
    new AsyncShowTimePicker(this, aCallback);
  return NS_DispatchToMainThread(filePickerEvent);
}