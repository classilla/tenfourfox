function* gen() { 
  yield 1;
  yield 2;
  yield 3;
}

var g = gen(); // "Generator { }"
assertEq(g.next().value, 1);
assertEq(g.next().value, 2);
