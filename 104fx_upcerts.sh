#!/bin/csh -f

if (! -e security/manager/ssl/nsSTSPreloadList.inc) then
	echo 'not in the tenfourfox folder, aborting'
endif

# certdata.txt is parsed by security/nss/lib/ckfw/builtins/certdata.perl
# which we patched to filter CKA_NSS_MOZILLA_CA_POLICY (unsupported by
# our version of NSS but required to assert roots in later versions).
# if we update NSS, we need to remove that patch (TenFourFox issue 512).

set verbose
set release_url=https://hg.mozilla.org/releases/mozilla-esr115/raw-file/tip/

# self test to ensure certificates and encryption methods are correct
curl ${release_url}/config/milestone.txt || exit

curl ${release_url}/security/manager/ssl/StaticHPKPins.h > security/manager/ssl/StaticHPKPins.h
curl ${release_url}/security/nss/lib/ckfw/builtins/certdata.txt > security/nss/lib/ckfw/builtins/certdata.txt
curl ${release_url}/netwerk/dns/effective_tld_names.dat > netwerk/dns/effective_tld_names.dat
curl ${release_url}/security/manager/ssl/nsSTSPreloadList.inc | perl ./104fx_import_esr102_stspreload.pl > security/manager/ssl/nsSTSPreloadList.inc
perl ./104fx_import_shavar_cryptominers.pl > caps/shavar-blocklist.h

