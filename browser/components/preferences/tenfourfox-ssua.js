/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

Components.utils.import("resource://gre/modules/Services.jsm");

const UA_PREF_BRANCH = "general.useragent.override.";

function SSUA(domain, ua)
{
  this.domain = domain;
  this.ua = ua;
}

var gTenFourFoxSSUAManager = {
  _type                 : "",
  _SSUAs                : [],
  _SSUAsToAdd           : new Map(), // also includes changes, necessarily
  _SSUAsToDelete        : new Map(),
  _bundle               : null,
  _pbundle              : null,
  _tree                 : null,
  _prefBranch           : null,

  _view: {
    _rowCount: 0,
    get rowCount()
    {
      return this._rowCount;
    },
    getCellText: function (aRow, aColumn)
    {
      if (aColumn.id == "domainCol")
        return gTenFourFoxSSUAManager._SSUAs[aRow].domain;
      else if (aColumn.id == "uaCol")
        return gTenFourFoxSSUAManager._SSUAs[aRow].ua;
      return "";
    },

    isSeparator: function(aIndex) { return false; },
    isSorted: function() { return false; },
    isContainer: function(aIndex) { return false; },
    setTree: function(aTree){},
    getImageSrc: function(aRow, aColumn) {},
    getProgressMode: function(aRow, aColumn) {},
    getCellValue: function(aRow, aColumn) {},
    cycleHeader: function(column) {},
    getRowProperties: function(row){ return ""; },
    getColumnProperties: function(column){ return ""; },
    getCellProperties: function(row,column){
      if (column.element.getAttribute("id") == "domainCol")
        return "ltr";

      return "";
    }
  },

  addSSUA: function ()
  {
    var textbox = document.getElementById("domain");
    var uabox = document.getElementById("ua");
    var input_dom = textbox.value.replace(/^\s*/, ""); // trim any leading space
    input_dom = input_dom.replace(/\s*$/,"");
    input_dom = input_dom.replace("http://", "");
    input_dom = input_dom.replace("https://", "");
    input_dom = input_dom.replace(/\//g, "");

    var ua = uabox.value.replace(/^\s*/, "");
    ua = ua.replace(/\s*$/, "");

    try {
      // Block things like hostname:port by making a URL and seeing if it rejects it.
      let uri = Services.io.newURI("http://"+input_dom+":80/", null, null);
      if (!uri.host) throw "as if";
    } catch(ex) {
      var message = this._pbundle.getString("invalidURI");
      var title = this._pbundle.getString("invalidURITitle");
      Services.prompt.alert(window, title, message);
      return;
    }

    // check whether the entry already exists, and if not, add it
    let already = false;
    for (var i = 0; i < this._SSUAs.length; ++i) {
      if (this._SSUAs[i].domain == input_dom) {
        already = true;
        this._SSUAs[i].ua = ua;
        this._SSUAsToAdd.set(input_dom, ua); // can go through same path
        this._resortSSUAs();
        break;
      }
    }

    if (!already) {
      this._SSUAsToAdd.set(input_dom, ua);
      this._addSSUAToList(input_dom, ua);
      ++this._view._rowCount;
      this._tree.treeBoxObject.rowCountChanged(this._view.rowCount - 1, 1);
      this._resortSSUAs();
    }

    textbox.value = "";
    uabox.value = "";
    textbox.focus();

    // covers a case where the site exists already, so the buttons don't disable
    this.onHostInput(textbox);

    // enable "remove all" button as needed
    document.getElementById("removeAllSSUAs").disabled = this._SSUAs.length == 0;
  },

  _removeSSUA: function(ssua)
  {
    for (let i = 0; i < this._SSUAs.length; ++i) {
      if (this._SSUAs[i].domain == ssua.domain) {
        this._SSUAs.splice(i, 1);
        this._view._rowCount--;
        this._tree.treeBoxObject.rowCountChanged(this._view.rowCount - 1, -1);
        this._tree.treeBoxObject.invalidate();
        break;
      }
    }

    // If this was added during this session, let's remove
    // it from the pending adds list to prevent extra work.
    let isnew = this._SSUAsToAdd.delete(ssua.domain);
    if (!isnew) {
      this._SSUAsToDelete.set(ssua.domain, ssua);
    }
  },

  _resortSSUAs: function()
  {
    gTreeUtils.sort(this._tree, this._view, this._SSUAs,
                    this._lastSSUAsortColumn,
                    this._SSUAsComparator,
                    this._lastSSUAsortColumn,
                    !this._lastSSUAsortAscending); // keep sort direction
    this._tree.treeBoxObject.invalidate();
  },

  onHostInput: function ()
  {
    let w = document.getElementById("domain").value;
    let x = document.getElementById("ua").value;
    document.getElementById("btnAdd").disabled = !w || !x || !w.length || !x.length
      || w.length == 0 || x.length == 0;
  },

  onWindowKeyPress: function (aEvent)
  {
    if (aEvent.keyCode == KeyEvent.DOM_VK_ESCAPE)
      window.close();
  },

  onHostKeyPress: function (aEvent)
  {
    if (aEvent.keyCode == KeyEvent.DOM_VK_RETURN)
      document.getElementById("btnAdd").click();
  },

  onLoad: function ()
  {
    this._bundle = document.getElementById("tenFourFoxPreferences");
    this._pbundle = document.getElementById("bundlePreferences");
    var params = window.arguments[0];
    this.init(params);
  },

  init: function (aParams)
  {
    if (this._type) {
      // reusing an open dialog, clear the old observer
      this.uninit();
    }
    this._type = aParams.type;
    _prefBranch = Services.prefs.getBranch(UA_PREF_BRANCH);

    var SSUAsText = document.getElementById("ssuaText");
    while (SSUAsText.hasChildNodes())
      SSUAsText.removeChild(SSUAsText.firstChild);
    SSUAsText.appendChild(document.createTextNode(aParams.introText));

    document.title = aParams.windowTitle;

    this.onHostInput();

    let treecols = document.getElementsByTagName("treecols")[0];
    treecols.addEventListener("click", event => {
      if (event.target.nodeName != "treecol" || event.button != 0) {
        return;
      }

      let sortField = event.target.getAttribute("data-field-name");
      if (!sortField) {
        return;
      }

      gTenFourFoxSSUAManager.onSSUAsort(sortField);
    });

    this._loadSSUAs();
    _prefBranch.addObserver("", this._loadSSUAs, false); // XXX: make this better

    document.getElementById("domain").focus();
  },

  uninit: function ()
  {
    _prefBranch.removeObserver("", this._loadSSUAs); // XXX
    this._type = "";
  },

  onSSUAselected: function ()
  {
    var hasSelection = this._tree.view.selection.count > 0;
    var hasRows = this._tree.view.rowCount > 0;
    document.getElementById("removeSSUA").disabled = !hasRows || !hasSelection;
    document.getElementById("removeAllSSUAs").disabled = !hasRows;
  },

  onSSUADeleted: function ()
  {
    if (!this._view.rowCount)
      return;
    var removedSSUAs = [];
    gTreeUtils.deleteSelectedItems(this._tree, this._view, this._SSUAs, removedSSUAs);
    for (var i = 0; i < removedSSUAs.length; ++i) {
      var p = removedSSUAs[i];
      this._removeSSUA(p);
    }
    document.getElementById("removeSSUA").disabled = !this._SSUAs.length;
    document.getElementById("removeAllSSUAs").disabled = !this._SSUAs.length;
  },

  onAllSSUAsDeleted: function ()
  {
    if (!this._view.rowCount)
      return;
    var removedSSUAs = [];
    gTreeUtils.deleteAll(this._tree, this._view, this._SSUAs, removedSSUAs);
    for (var i = 0; i < removedSSUAs.length; ++i) {
      var p = removedSSUAs[i];
      this._removeSSUA(p);
    }
    document.getElementById("removeSSUA").disabled = true;
    document.getElementById("removeAllSSUAs").disabled = true;
  },

  onSSUAKeyPress: function (aEvent)
  {
    if (aEvent.keyCode == KeyEvent.DOM_VK_DELETE
#ifdef XP_MACOSX
        || aEvent.keyCode == KeyEvent.DOM_VK_BACK_SPACE
#endif
       )
      this.onSSUADeleted();
  },

  _lastSSUAsortColumn: "",
  _lastSSUAsortAscending: false,
  _SSUAsComparator : function (a, b)
  {
    return a.toLowerCase().localeCompare(b.toLowerCase());
  },


  onSSUAsort: function (aColumn)
  {
    this._lastSSUAsortAscending = gTreeUtils.sort(this._tree,
                                                        this._view,
                                                        this._SSUAs,
                                                        aColumn,
                                                        this._SSUAsComparator,
                                                        this._lastSSUAsortColumn,
                                                        this._lastSSUAsortAscending);
    this._lastSSUAsortColumn = aColumn;
  },

  onApplyChanges: function()
  {
    // Stop observing changes since we are about
    // to write out the pending adds/deletes and don't need
    // to update the UI.
    this.uninit();

    // Create and clear prefs out of whole cloth; don't use the
    // pref branch because it may not exist yet.
    for (let i of this._SSUAsToAdd.keys()) {
      Services.prefs.setCharPref(UA_PREF_BRANCH+i, this._SSUAsToAdd.get(i));
    }

    for (let i of this._SSUAsToDelete.keys()) {
      Services.prefs.clearUserPref(UA_PREF_BRANCH+i);
    }

    window.close();
  },

  fillUA: function(popup)
  {
    if (popup.value == "")
      document.getElementById("ua").value = "";
    else
      document.getElementById("ua").value = gTenFourFoxPane.validUA[popup.value];
    this.onHostInput();
  },

  _loadSSUAs: function ()
  {
    this._tree = document.getElementById("SSUAsTree");
    this._SSUAs = [];

    // load SSUAs into a table
    let count = 0;
    let domains = _prefBranch.getChildList("");
    for (let domain of domains) {
      this._addSSUAToList(domain, _prefBranch.getCharPref(domain));
    }

    this._view._rowCount = this._SSUAs.length;

    // sort and display the table
    this._tree.view = this._view;
    this.onSSUAsort("domain");

    // disable "remove all" button if there are none
    document.getElementById("removeAllSSUAs").disabled = this._SSUAs.length == 0;
  },

  _addSSUAToList: function (domain, ua)
  {
    var p = new SSUA(domain, ua);
    this._SSUAs.push(p);
  },

};

function initWithParams(aParams)
{
  gTenFourFoxSSUAManager.init(aParams);
}
