/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Basic syntactic tests for issue 521. */

var Promise = ShellPromise;

function assertThrowsSE(code) {
  assertThrows(() => Reflect.parse(code), SyntaxError);
}

    assertThrowsSE("'use strict'; async function eval() {}");
    assertThrowsSE("'use strict'; async function arguments() {}");
    assertThrowsSE("async function a(k = super.prop) { }");
    assertThrowsSE("async function a() { super.prop(); }");
    assertThrowsSE("async function a() { super(); }");

    assertThrowsSE("async function a(k = await 3) {}");

async function test() { }
var anon = async function() { }
assertEq(test.name, "test");
assertEq(anon.name, "");

function okok(x, y, z) { return (typeof y === "function"); }
assertEq(okok(5, async function(w) { await w+w; }, "ok"), true);
assertEq(okok(6, (async(w)=>{await w+w}), "ok"), true);
assertEq(okok(7, ()=>{!async function(){ }}, "ok"), true);

function yoyo(k) { return new Promise(resolve => { resolve(k+1); }); }
async function dodo(k) { return await yoyo(k+1); }
// Just make sure this executes. It currently returns ({ }) in the shell.
dodo(5);

if (typeof reportCompare === "function")
    reportCompare(true, true);

