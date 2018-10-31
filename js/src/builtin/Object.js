/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// ES6 draft rev36 2015-03-17 19.1.2.1
function ObjectStaticAssign(target, firstSource) {
    // Steps 1-2.
    var to = ToObject(target);

    // Step 3.
    if (arguments.length < 2)
        return to;

    // Steps 4-5.
    for (var i = 1; i < arguments.length; i++) {
        // Step 5.a.
        var nextSource = arguments[i];
        if (nextSource === null || nextSource === undefined)
            continue;

        // Steps 5.b.i-ii.
        var from = ToObject(nextSource);

        // Steps 5.b.iii-iv.
        var keys = OwnPropertyKeys(from, JSITER_OWNONLY | JSITER_HIDDEN | JSITER_SYMBOLS);

        // Step 5.c.
        for (var nextIndex = 0, len = keys.length; nextIndex < len; nextIndex++) {
            var nextKey = keys[nextIndex];

            // Steps 5.c.i-iii. We abbreviate this by calling propertyIsEnumerable
            // which is faster and returns false for not defined properties.
            if (callFunction(std_Object_propertyIsEnumerable, from, nextKey)) {
                // Steps 5.c.iii.1-4.
                to[nextKey] = from[nextKey];
            }
        }
    }

    // Step 6.
    return to;
}

// ES stage 4 proposal
function ObjectGetOwnPropertyDescriptors(O) {
    // Step 1.
    var obj = ToObject(O);

    // Step 2.
    var keys = OwnPropertyKeys(obj, JSITER_OWNONLY | JSITER_HIDDEN | JSITER_SYMBOLS);

    // Step 3.
    var descriptors = {};

    // Step 4.
    for (var index = 0, len = keys.length; index < len; index++) {
        var key = keys[index];

        // Steps 4.a-b.
        var desc = std_Object_getOwnPropertyDescriptor(obj, key);

        // Step 4.c.
        if (typeof desc !== "undefined")
            _DefineDataProperty(descriptors, key, desc);
    }

    // Step 5.
    return descriptors;
}

/* ES6 draft rev 32 (2015 Feb 2) 19.1.2.9. */
function ObjectGetPrototypeOf(obj) {
    return std_Reflect_getPrototypeOf(ToObject(obj));
}

/* ES6 draft rev 32 (2015 Feb 2) 19.1.2.11. */
function ObjectIsExtensible(obj) {
    return IsObject(obj) && std_Reflect_isExtensible(obj);
}

/* ES2015 19.1.3.5 Object.prototype.toLocaleString */
function Object_toLocaleString() {
    // Step 1.
    var O = this;

    // Step 2.
    return callFunction(O.toString, O);
}

function ObjectDefineSetter(name, setter) {
    var object;
    if (this === null || this === undefined)
        object = global;
    else
        object = ToObject(this);

    if (!IsCallable(setter))
        ThrowTypeError(JSMSG_BAD_GETTER_OR_SETTER, "setter");

    var key = ToPropertyKey(name);

    var desc = {
        __proto__: null,
        enumerable: true,
        configurable: true,
        set: setter
    };

    std_Object_defineProperty(object, key, desc);
}

function ObjectDefineGetter(name, getter) {
    var object;
    if (this === null || this === undefined)
        object = global;
    else
        object = ToObject(this);

    if (!IsCallable(getter))
        ThrowTypeError(JSMSG_BAD_GETTER_OR_SETTER, "getter");

    var key = ToPropertyKey(name);

    var desc = {
        __proto__: null,
        enumerable: true,
        configurable: true,
        get: getter
    };

    std_Object_defineProperty(object, key, desc);
}

function ObjectLookupSetter(name) {
    var key = ToPropertyKey(name);
    var object = ToObject(this);

    do {
        var desc = std_Object_getOwnPropertyDescriptor(object, key);
        if (desc) {
            if (callFunction(std_Object_hasOwnProperty, desc, "set"))
                return desc.set;
            return undefined;
        }
        object = std_Reflect_getPrototypeOf(object);
    } while (object !== null);
}

function ObjectLookupGetter(name) {
    var key = ToPropertyKey(name);
    var object = ToObject(this);

    do {
        var desc = std_Object_getOwnPropertyDescriptor(object, key);
        if (desc) {
            if (callFunction(std_Object_hasOwnProperty, desc, "get"))
                return desc.get;
            return undefined;
        }
        object = std_Reflect_getPrototypeOf(object);
    } while (object !== null);
}
