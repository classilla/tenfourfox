var Q = 0;
// We won't throw in IonPower; just don't crash.
var thrown = true;
try {
   (function f(i) { Q = i; if (i == 200000) return; f(i+1); })(1)
} catch (e) {
    thrown = true;
}

// Exact behavior of recursion check depends on which JIT we use.
assertEq(thrown && Q > 3500, true);
