/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#ifndef NSDATEPICKERPROXY_H
#define NSDATEPICKERPROXY_H

#include "nsBaseDatePicker.h"
#include "nsString.h"
#include "nsIURI.h"
#include "nsTArray.h"
#include "nsCOMArray.h"

#include "mozilla/dom/PDatePickerChild.h"

class nsIWidget;
class nsIFile;
class nsPIDOMWindow;

namespace mozilla {
namespace dom {
class File;
} // namespace dom
} // namespace mozilla

/*

  This class creates a proxy date picker to be used in content processes.
  The date picker just collects the initialization data and when Show() is
  called, remotes everything to the chrome process which in turn can show a
  platform specific date picker.

  I'm not sure why I'm implementing this for TenFourFox given that we'll never
  run in e10s, but anyway.

*/
class nsDatePickerProxy : public nsBaseDatePicker,
                          public mozilla::dom::PDatePickerChild
{
public:
    nsDatePickerProxy();

    NS_DECL_ISUPPORTS

    // nsIDatePicker
    NS_IMETHODIMP Init(nsIDOMWindow* aParent, const nsAString& aTitle) override;
    NS_IMETHODIMP Open(nsIDatePickerShownCallback* aCallback) override;
    NS_IMETHODIMP Show(int16_t *_retval) override;
    NS_IMETHODIMP GetDefaultDate(nsAString &aDefaultDate) override;
    NS_IMETHODIMP SetDefaultDate(const nsAString &aDefaultDate) override;
    NS_IMETHODIMP GetMinDate(nsAString &aMinDate) override;
    NS_IMETHODIMP SetMinDate(const nsAString &aMinDate) override;
    NS_IMETHODIMP GetMaxDate(nsAString &aMaxDate) override;
    NS_IMETHODIMP SetMaxDate(const nsAString &aMaxDate) override;
    NS_IMETHODIMP GetSelectedDate(nsAString &aSelectedDate);

    // PDatePickerChild
    virtual bool Recv__delete__(const nsString& date, const int16_t& aResult);
    virtual bool RecvUpdate(const nsString& date);

private:
    ~nsDatePickerProxy();
    void InitNative(nsIWidget*, const nsAString&) override;

    nsCOMPtr<nsIDatePickerShownCallback> mCallback;
};

#endif // NSDATEPICKERPROXY_H
