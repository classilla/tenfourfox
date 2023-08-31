var g = newGlobal({newCompartment: true});

try {
  undef()
} catch (err) {
  const handler = { "getPrototypeOf": (x) => () => x };
  const proxy = new g.Proxy(err, handler);
  try {
    proxy.stack
/* odds are we weren't exploitable because we don't support pure catch,
   but now it's not a problem */
  } catch(e) {}
}
