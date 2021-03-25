/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

Components.utils.import("resource://gre/modules/Services.jsm");

const AUTORV_PREF_BRANCH = "tenfourfox.reader.auto.";

function AutoRV(domain, mode)
{
  this.domain = domain;
  this.mode = mode;
}

var gTenFourFoxAutoRVManager = {
  _type                 : "",
  _AutoRVs                : [],
  _AutoRVsToAdd           : new Map(), // also includes changes, necessarily
  _AutoRVsToDelete        : new Map(),
  _bundle               : null,
  _pbundle              : null,
  _tree                 : null,
  _prefBranch           : null,

  _allpText             : null,
  _subpText             : null,
  _modeToString : function(mode) {
    if (!this._allpText)
      this._allpText = document.getElementById("rvmodey").label;
    if (!this._subpText)
      this._subpText = document.getElementById("rvmodes").label;

    return (mode == "s") ? this._subpText : this._allpText;
  },

  _view: {
    _rowCount: 0,
    get rowCount()
    {
      return this._rowCount;
    },
    getCellText: function (aRow, aColumn)
    {
      if (aColumn.id == "domainCol")
        return gTenFourFoxAutoRVManager._AutoRVs[aRow].domain;
      else if (aColumn.id == "modeCol")
        return gTenFourFoxAutoRVManager._modeToString(gTenFourFoxAutoRVManager._AutoRVs[aRow].mode);
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

  addAutoRV: function ()
  {
    var textbox = document.getElementById("domain");
    var input_dom = textbox.value.replace(/^\s*/, ""); // trim any leading space
    input_dom = input_dom.replace(/\s*$/,"");
    input_dom = input_dom.replace("http://", "");
    input_dom = input_dom.replace("https://", "");
    input_dom = input_dom.replace(/\//g, "");

    var modebox = document.getElementById("mode");
    var mode = modebox.value;

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
    for (var i = 0; i < this._AutoRVs.length; ++i) {
      if (this._AutoRVs[i].domain == input_dom) {
        already = true;
        this._AutoRVs[i].mode = mode;
        this._AutoRVsToAdd.set(input_dom, mode); // can go through same path
        this._resortAutoRVs();
        break;
      }
    }

    if (!already) {
      this._AutoRVsToAdd.set(input_dom, mode);
      this._addAutoRVToList(input_dom, mode);
      ++this._view._rowCount;
      this._tree.treeBoxObject.rowCountChanged(this._view.rowCount - 1, 1);
      this._resortAutoRVs();
    }

    textbox.value = "";
    modebox.value = "";
    textbox.focus();

    // covers a case where the site exists already, so the buttons don't disable
    this.onHostInput(textbox);

    // enable "remove all" button as needed
    document.getElementById("removeAllAutoRVs").disabled = this._AutoRVs.length == 0;
  },

  _removeAutoRV: function(autorv)
  {
    for (let i = 0; i < this._AutoRVs.length; ++i) {
      if (this._AutoRVs[i].domain == autorv.domain) {
        this._AutoRVs.splice(i, 1);
        this._view._rowCount--;
        this._tree.treeBoxObject.rowCountChanged(this._view.rowCount - 1, -1);
        this._tree.treeBoxObject.invalidate();
        break;
      }
    }

    // If this was added during this session, let's remove
    // it from the pending adds list to prevent extra work.
    let isnew = this._AutoRVsToAdd.delete(autorv.domain);
    if (!isnew) {
      this._AutoRVsToDelete.set(autorv.domain, autorv);
    }
  },

  _resortAutoRVs: function()
  {
    gTreeUtils.sort(this._tree, this._view, this._AutoRVs,
                    this._lastAutoRVsortColumn,
                    this._AutoRVsComparator,
                    this._lastAutoRVsortColumn,
                    !this._lastAutoRVsortAscending); // keep sort direction
    this._tree.treeBoxObject.invalidate();
  },

  onHostInput: function ()
  {
    let w = document.getElementById("domain").value;
    let x = document.getElementById("mode").value;
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
    _prefBranch = Services.prefs.getBranch(AUTORV_PREF_BRANCH);

    var AutoRVsText = document.getElementById("autorvText");
    while (AutoRVsText.hasChildNodes())
      AutoRVsText.removeChild(AutoRVsText.firstChild);
    AutoRVsText.appendChild(document.createTextNode(aParams.introText));

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

      gTenFourFoxAutoRVManager.onAutoRVsort(sortField);
    });

    this._loadAutoRVs();
    _prefBranch.addObserver("", this._loadAutoRVs, false); // XXX: make this better

    document.getElementById("domain").focus();
  },

  uninit: function ()
  {
    _prefBranch.removeObserver("", this._loadAutoRVs); // XXX
    this._type = "";
  },

  onAutoRVselected: function ()
  {
    var hasSelection = this._tree.view.selection.count > 0;
    var hasRows = this._tree.view.rowCount > 0;
    document.getElementById("removeAutoRV").disabled = !hasRows || !hasSelection;
    document.getElementById("removeAllAutoRVs").disabled = !hasRows;
  },

  onAutoRVDeleted: function ()
  {
    if (!this._view.rowCount)
      return;
    var removedAutoRVs = [];
    gTreeUtils.deleteSelectedItems(this._tree, this._view, this._AutoRVs, removedAutoRVs);
    for (var i = 0; i < removedAutoRVs.length; ++i) {
      var p = removedAutoRVs[i];
      this._removeAutoRV(p);
    }
    document.getElementById("removeAutoRV").disabled = !this._AutoRVs.length;
    document.getElementById("removeAllAutoRVs").disabled = !this._AutoRVs.length;
  },

  onAllAutoRVsDeleted: function ()
  {
    if (!this._view.rowCount)
      return;
    var removedAutoRVs = [];
    gTreeUtils.deleteAll(this._tree, this._view, this._AutoRVs, removedAutoRVs);
    for (var i = 0; i < removedAutoRVs.length; ++i) {
      var p = removedAutoRVs[i];
      this._removeAutoRV(p);
    }
    document.getElementById("removeAutoRV").disabled = true;
    document.getElementById("removeAllAutoRVs").disabled = true;
  },

  onAutoRVKeyPress: function (aEvent)
  {
    if (aEvent.keyCode == KeyEvent.DOM_VK_DELETE
#ifdef XP_MACOSX
        || aEvent.keyCode == KeyEvent.DOM_VK_BACK_SPACE
#endif
       )
      this.onAutoRVDeleted();
  },

  _lastAutoRVsortColumn: "",
  _lastAutoRVsortAscending: false,
  _AutoRVsComparator : function (a, b)
  {
    return a.toLowerCase().localeCompare(b.toLowerCase());
  },


  onAutoRVsort: function (aColumn)
  {
    this._lastAutoRVsortAscending = gTreeUtils.sort(this._tree,
                                                        this._view,
                                                        this._AutoRVs,
                                                        aColumn,
                                                        this._AutoRVsComparator,
                                                        this._lastAutoRVsortColumn,
                                                        this._lastAutoRVsortAscending);
    this._lastAutoRVsortColumn = aColumn;
  },

  onApplyChanges: function()
  {
    // Stop observing changes since we are about
    // to write out the pending adds/deletes and don't need
    // to update the UI.
    this.uninit();

    // Create and clear prefs out of whole cloth; don't use the
    // pref branch because it may not exist yet.
    for (let i of this._AutoRVsToAdd.keys()) {
      Services.prefs.setCharPref(AUTORV_PREF_BRANCH+i, this._AutoRVsToAdd.get(i));
    }

    for (let i of this._AutoRVsToDelete.keys()) {
      Services.prefs.clearUserPref(AUTORV_PREF_BRANCH+i);
    }

    window.close();
  },

  _loadAutoRVs: function ()
  {
    this._tree = document.getElementById("AutoRVsTree");
    this._AutoRVs = [];

    // load AutoRVs into a table
    let count = 0;
    let domains = _prefBranch.getChildList("");
    for (let domain of domains) {
      this._addAutoRVToList(domain, _prefBranch.getCharPref(domain));
    }

    this._view._rowCount = this._AutoRVs.length;

    // sort and display the table
    this._tree.view = this._view;
    this.onAutoRVsort("domain");

    // disable "remove all" button if there are none
    document.getElementById("removeAllAutoRVs").disabled = this._AutoRVs.length == 0;
  },

  _addAutoRVToList: function (domain, mode)
  {
    var p = new AutoRV(domain, mode);
    this._AutoRVs.push(p);
  },

};

function initWithParams(aParams)
{
  gTenFourFoxAutoRVManager.init(aParams);
}
