// -*- indent-tabs-mode: nil; js-indent-level: 2 -*-

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

var jsToggle = {

  get _prefBranch() {
    delete this._prefBranch;
    return this._prefBranch = Components.classes["@mozilla.org/preferences-service;1"]
                                        .getService(Components.interfaces.nsIPrefBranch);
  },

  get executeJs() {
    return this._prefBranch.getBoolPref("javascript.enabled");
  },

  set executeJs(aVal) {
    this._prefBranch.setBoolPref("javascript.enabled", aVal);
    return aVal;
  },

  updateMenu: function jsToggle_updateMenu() {
    var menuItem = document.getElementById("toggle_javascript");

    menuItem.setAttribute("checked", this.executeJs);
  },

  toggle: function jsToggle_toggle() {

    this.executeJs = !this.executeJs;

  }
};

