/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#ifndef NSTIMEPICKERPROXY_H
#define NSTIMEPICKERPROXY_H

#include "nsBaseTimePicker.h"
#include "nsString.h"
#include "nsIURI.h"
#include "nsTArray.h"
#include "nsCOMArray.h"

#include "mozilla/dom/PTimePickerChild.h"

class nsIWidget;
class nsIFile;
class nsPIDOMWindow;

namespace mozilla {
namespace dom {
class File;
} // namespace dom
} // namespace mozilla

/*

  This class creates a proxy time picker to be used in content processes.
  The time picker just collects the initialization data and when Show() is
  called, remotes everything to the chrome process which in turn can show a
  platform specific time picker.

  I'm not sure why I'm implementing this for TenFourFox given that we'll never
  run in e10s, but anyway.

*/
class nsTimePickerProxy : public nsBaseTimePicker,
                          public mozilla::dom::PTimePickerChild
{
public:
    nsTimePickerProxy();

    NS_DECL_ISUPPORTS

    // nsITimePicker
    NS_IMETHODIMP Init(nsIDOMWindow* aParent, const nsAString& aTitle) override;
    NS_IMETHODIMP Open(nsITimePickerShownCallback* aCallback) override;
    NS_IMETHODIMP Show(int16_t *_retval) override;
    NS_IMETHODIMP GetDefaultTime(nsAString &aDefaultTime) override;
    NS_IMETHODIMP SetDefaultTime(const nsAString &aDefaultTime) override;
    NS_IMETHODIMP GetMinTime(nsAString &aMinTime) override;
    NS_IMETHODIMP SetMinTime(const nsAString &aMinTime) override;
    NS_IMETHODIMP GetMaxTime(nsAString &aMaxTime) override;
    NS_IMETHODIMP SetMaxTime(const nsAString &aMaxTime) override;
    NS_IMETHODIMP GetStep(double *aStep) override;
    NS_IMETHODIMP SetStep(const double aStep) override;
    NS_IMETHODIMP GetSelectedTime(nsAString &aSelectedTime);

    // PTimePickerChild
    virtual bool Recv__delete__(const nsString& time, const int16_t& aResult);
    virtual bool RecvUpdate(const nsString& time);

private:
    ~nsTimePickerProxy();
    void InitNative(nsIWidget*, const nsAString&) override;

    nsCOMPtr<nsITimePickerShownCallback> mCallback;
};

#endif // NSTIMEPICKERPROXY_H
