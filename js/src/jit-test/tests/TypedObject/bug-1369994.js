var lfLogBuffer = `
function f() {
    var i32 = new Int32Array(1);
    var f32 = new Float32Array(i32.buffer);
    for (var i = 0; i < 3; i++) {
      var { regExp, get,     }  = gczeal(9,10)
        ? (yield) : (yield) = call(f32, "i32.store", []);
    }
}
f();
`;
loadFile(lfLogBuffer);
function loadFile(lfVarx) {
    try {
      oomTest(function() { eval(lfVarx); });
    } catch (lfVare) {}
}

