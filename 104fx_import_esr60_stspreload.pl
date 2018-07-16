#!/usr/bin/perl -s

$source ||= "../esr60/security/manager/ssl/nsSTSPreloadList.inc";
open(W, $source) || die("unable to open $source: $!\nspecify -source=/path ?\n");
print <<'EOF';
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/*****************************************************************************/
/* This is an automatically generated file. If you're not                    */
/* nsSiteSecurityService.cpp, you shouldn't be #including it.                */
/*****************************************************************************/

/* imported from ESR60 by TenFourFox conversion script */

#include <stdint.h>
EOF

# let's have a little paranoia.
while(<W>) {
	if (/^const PRTime gPreloadListExpirationTime = INT64_C/) {
		print;
		$got_time = 1;
	}
	if (/%%/) {
		$got_delim = 1;
		last;
	}
}
die("unexpected format of $source\n") if (!$got_time || !$got_delim);
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
	chomp;
	last if (/%%/);
	($host, $subd, $crap) = split(/, /, $_, 3);
	if (!length($crap) && length($host) &&
			($subd eq '0' || $subd eq '1')) {
		print "  { \"$host\", ";
		print (($subd eq '1') ? "true" : "false");
		print " },\n";
	} else {
		die("unexpected line: $_\n");
	}
}

print "};\n";

