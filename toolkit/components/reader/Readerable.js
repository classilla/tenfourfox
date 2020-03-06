// -*- indent-tabs-mode: nil; js-indent-level: 2 -*-
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */
"use strict";

// This file and Readability-readerable.js are merged together into
// Readerable.jsm.

/* exported Readerable */
/* import-globals-from Readability-readerable.js */

const { classes: Cc, interfaces: Ci, utils: Cu } = Components;

Cu.import("resource://gre/modules/Services.jsm");
Cu.import("resource://gre/modules/XPCOMUtils.jsm");

function isNodeVisible(node) {
  return node.clientHeight > 0 && node.clientWidth > 0;
}

var Readerable = {
  isEnabled: true,
  isForceEnabled: false,

  get isEnabledForParseOnLoad() {
    return this.isEnabled || this.isForceEnabled;
  },

  /**
   * Decides whether or not a document is reader-able without parsing the whole thing.
   *
   * @param doc A document to parse.
   * @return boolean Whether or not we should show the reader mode button.
   */
  isProbablyReaderable(doc) {
    // Only care about 'real' HTML documents:
    if (doc.mozSyntheticDocument || !(doc instanceof doc.defaultView.HTMLDocument)) {
      return false;
    }

    let uri = Services.io.newURI(doc.location.href, null, null);
    if (!this.shouldCheckUri(uri)) {
      return false;
    }
    return isProbablyReaderable(doc, isNodeVisible);
  },

   _blockedHosts: [
    "amazon.com",
    "github.com",
    "mail.google.com",
    "pinterest.com",
    "reddit.com",
    "twitter.com",
    "youtube.com",
  ],

  shouldCheckUri(uri, isBaseUri = false) {
    if (!(uri.schemeIs("http") || uri.schemeIs("https"))) {
      return false;
    }
    if (!(this.isEnabledForParseOnLoad)) {
      // TenFourFox issue 585
      // Do this check here as well.
      return false;
    }
    if (!isBaseUri) {
      // Sadly, some high-profile pages have false positives, so bail early for those:
      let asciiHost = uri.asciiHost;
      if (this._blockedHosts.some(blockedHost => asciiHost.endsWith(blockedHost))) {
         return false;
      }
      if (uri.filePath == "/") {
        return false;
      }
    }

    return true;
  },

  observe: function(aMessage, aTopic, aData) {
    switch(aTopic) {
      case "nsPref:changed":
        if (aData === "reader.parse-on-load.enabled") {
          this.isEnabled = Services.prefs.getBoolPref(aData);
        } else if (aData === "reader.parse-on-load.force-enabled") {
          this.isForceEnabled = Services.prefs.getBoolPref(aData);
        }
        break;
    }
  }
};
Services.prefs.addObserver("reader.parse-on-load.", Readerable, false);
// Get the prefs when we start up (TenFourFox issue 585).
Readerable.isEnabled = Services.prefs.getBoolPref(
  "reader.parse-on-load.enabled");
Readerable.isForceEnabled = Services.prefs.getBoolPref(
  "reader.parse-on-load.force-enabled");

