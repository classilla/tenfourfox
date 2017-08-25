// array comprehensions
var data = "abcdefg";
var hexString = [
	data.charCodeAt(i) for (i in data) if (data.charCodeAt(i) < 100)
].join(",");
assertEq(hexString, "97,98,99");

// generator comprehensions
var it = [1, 2, 3, 5, 8, 10, 13];
var w = (i*2 for (i of it) if (i & 1));
assertEq(w.next(), 2);
assertEq(w.next(), 6);
assertEq(w.next(), 10);
assertEq(w.next(), 26);
