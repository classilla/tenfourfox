/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Mozilla XUL Toolkit.
 *
 * The Initial Developer of the Original Code is
 * the Mozilla Foundation.
 * Portions created by the Initial Developer are Copyright (C) 2010
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *   Scott Greenlay <scott@greenlay.net>
 *   Cameron Kaiser <classilla@floodgap.com>
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

#include "nsXPCOM.h"
#include "nsApplescriptService.h"

#ifdef XP_MACOSX
#include "MacScripting.h"
#endif

NS_IMPL_ISUPPORTS(nsApplescriptService, nsIApplescriptService)

nsApplescriptService::nsApplescriptService()
{
#ifdef XP_MACOSX
  SetupMacScripting();
#endif
}

nsApplescriptService::~nsApplescriptService()
{
}

NS_IMETHODIMP
nsApplescriptService::GetWindows(nsIArray **windows)
{
  if (windowCallback) {
    return windowCallback->GetWindows(windows);
  }
  *windows = NULL;
  return NS_OK;
}

NS_IMETHODIMP
nsApplescriptService::CreateWindowAtIndex(uint32_t index)
{
  NS_ASSERTION(index == 0, "Not implemented for window indices other than zero");
  if (windowCallback) {
    return windowCallback->CreateWindowAtIndex(index);
  }
  return NS_OK;
}

NS_IMETHODIMP
nsApplescriptService::CloseWindowAtIndex(uint32_t index)
{
  if (windowCallback) {
    return windowCallback->CloseWindowAtIndex(index);
  }
  return NS_OK;
}

NS_IMETHODIMP
nsApplescriptService::GetTabsInWindow(uint32_t index, nsIArray **tabs) {
  if (tabCallback) {
    return tabCallback->GetTabsInWindow(index, tabs);
  }
  *tabs = NULL;
  return NS_OK;
}

NS_IMETHODIMP
nsApplescriptService::GetCurrentTabInWindow(uint32_t index, uint32_t *tab_index, nsIDOMWindow **window) {
  if (tabCallback) {
    return tabCallback->GetCurrentTabInWindow(index, tab_index, window);
  }
  if (tab_index) {
    tab_index = 0;
  }
  *window = NULL;
  return NS_OK;
}

NS_IMETHODIMP
nsApplescriptService::SetCurrentTabInWindow(uint32_t index, uint32_t window_index) {
  if (tabCallback) {
    return tabCallback->SetCurrentTabInWindow(index, window_index);
  }
  return NS_OK;
}

NS_IMETHODIMP
nsApplescriptService::CreateTabAtIndexInWindow(uint32_t index, uint32_t window_index) {
  if (tabCallback) {
    return tabCallback->CreateTabAtIndexInWindow(index, window_index);
  }
  return NS_OK;
}

NS_IMETHODIMP
nsApplescriptService::CloseTabAtIndexInWindow(uint32_t index, uint32_t window_index) {
  if (tabCallback) {
    return tabCallback->CloseTabAtIndexInWindow(index, window_index);
  }
  return NS_OK;
}

NS_IMETHODIMP
nsApplescriptService::RegisterWindowCallback(nsIApplescriptWindowCallback *callback) {
  windowCallback = callback;
  return NS_OK;
}

NS_IMETHODIMP
nsApplescriptService::RegisterTabCallback(nsIApplescriptTabCallback *callback) {
  tabCallback = callback;
  return NS_OK;
}
