#!/usr/bin/perl -s

$source ||= "../esr52/security/manager/ssl/nsSTSPreloadList.inc";
open(W, $source) || die("unable to open $source: $!\nspecify -source=/path ?\n");
print <<'EOF';
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/*****************************************************************************/
/* This is an automatically generated file. If you're not                    */
/* nsSiteSecurityService.cpp, you shouldn't be #including it.                */
/*****************************************************************************/

/* imported from ESR52 by TenFourFox conversion script */

#include <stdint.h>
EOF

# let's have a little paranoia.
while(<W>) {
	if (/^const PRTime gPreloadListExpirationTime = INT64_C/) {
		print;
		$got_time = 1;
	}
	if (/kSTSHostTable/) {
		$got_host = 1;
		last;
	}
}
die("unexpected format of $source\n") if (!$got_time || !$got_host);
print <<'EOF';

class nsSTSPreload
{
  public:
    const char *mHost;
    const bool mIncludeSubdomains;
};

static const nsSTSPreload kSTSPreloadList[] = {
EOF

while(<W>) {
	if (/^\s*\/\* ("[^"]+", )(true|false)\s\*\//) {
		print "  { $1$2 },\n";
	}
}

print "};\n";

