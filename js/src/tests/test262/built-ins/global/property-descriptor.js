// Copyright (C) 2016 Jordan Harband. All rights reserved.
// This code is governed by the BSD license found in the LICENSE file.

/*---
esid: sec-other-properties-of-the-global-object-global
description: "'globalThis' should be writable, non-enumerable, and configurable"
author: Jordan Harband
includes: [propertyHelper.js]
features: [globalThis]
---*/

verifyNotEnumerable(this, 'globalThis');
verifyWritable(this, 'globalThis');
verifyConfigurable(this, 'globalThis');

reportCompare(0, 0);
