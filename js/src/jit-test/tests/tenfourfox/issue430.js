function
    request(endpoint, {
      httpMethod = 'GET',
      params = {},
      resultAs = 'json',
      data = {}
    } = {}) {
	return resultAs;
}

assertEq(request(), "json");
assertEq(request(null, { httpMethod: 'POST' }), "json");
assertEq(request(null, { resultAs: 'xml' }), "xml");
