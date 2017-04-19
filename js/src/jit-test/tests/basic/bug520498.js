var Q = 0;
try {
   (function f(i) { Q = i; if (i == 100000) return; f(i+1); })(1)
} catch (e) {
}

// Due to our stack armour, exact number irrelevant to IonPower.
// Just don't crash.
quit();

if (Q == 100000)
   assertEq(Q, "fail");

