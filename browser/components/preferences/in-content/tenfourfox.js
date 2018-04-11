/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Custom TenFourFox prefpanel (C)2016 Cameron Kaiser */

Components.utils.import("resource://gre/modules/AppConstants.jsm");
Components.utils.import("resource://gre/modules/Services.jsm");

var gTenFourFoxPane = {

  init: function ()
  {
    function setEventListener(aId, aEventType, aCallback) /* future expansion */
    {
      document.getElementById(aId)
              .addEventListener(aEventType, aCallback.bind(gTenFourFoxPane));
    }

    /* setEventListener("historyDontRememberClear", "click", function () {
      gPrivacyPane.clearPrivateDataNow(true);
      return false;
    }); */
  },
  
  // We have to invert the sense for the pdfjs.disabled pref, since true equals DISabled.

  readPDFjs: function ()
  {
    var pref = document.getElementById("pdfjs.disabled");
    return (!(pref.value));
  },
  writePDFjs: function ()
  {
    var nupref = document.getElementById("pdfJsCheckbox");
    return (!(nupref.checked));
  },
  
  // Find and set the appropriate UA string based on the UA template.
  validUA : {
      "fx" : "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.13; rv:52.0) Gecko/20100101 Firefox/52.0",
      "fx60" : "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.13; rv:60.0) Gecko/20100101 Firefox/60.0",
      "classilla" : "NokiaN90-1/3.0545.5.1 Series60/2.8 Profile/MIDP-2.0 Configuration/CLDC-1.1 (en-US; rv:9.3.3) Clecko/20141026 Classilla/CFM",
      "ie8" : "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)",
      "ie11" : "Mozilla/5.0 (Windows NT 10.0; WOW64; Trident/7.0; rv:11.0) like Gecko",
      "android" : "Mozilla/5.0 (Linux; Android 8.1.0; Pixel XL Build/OPM1.171019.021) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.109 Mobile Safari/537.36",
      "ipad" : "Mozilla/5.0 (iPhone; CPU iPhone OS 11_2_6 like Mac OS X) AppleWebKit/604.5.6 (KHTML, like Gecko) Version/11.0 Mobile/15D100 Safari/604.1"
  },
  _prefSvc: Cc["@mozilla.org/preferences-service;1"].getService(Ci.nsIPrefBranch),
  readUA: function ()
  {
    var pref = document.getElementById("tenfourfox.ua.template");
    if (!pref) return "";

    // Synchronize the pref on entry in case it's stale.
    pref = pref.value;
    if (this.validUA[pref]) {
        this._prefSvc.setCharPref("general.useragent.override", this.validUA[pref]);
        return pref;
    }
    return "";
  },
  writeUA : function()
  {
    var nupref = document.getElementById("uaBox").value;
    if (this.validUA[nupref]) {
        this._prefSvc.setCharPref("general.useragent.override", this.validUA[nupref]);
        return nupref;
    }
    this._prefSvc.clearUserPref("general.useragent.override");
    return "";
  }, 
};
