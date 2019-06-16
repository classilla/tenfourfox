#!/bin/csh -f

if (! -e security/manager/ssl/nsSTSPreloadList.inc) then
	echo 'not in the tenfourfox folder, aborting'
endif

# certdata.txt is parsed by security/nss/lib/ckfw/builtins/certdata.perl
# which we patched to filter CKA_NSS_MOZILLA_CA_POLICY (unsupported by
# our version of NSS but required to assert roots in later versions).
# if we update NSS, we need to remove that patch (TenFourFox issue 512).

set verbose
cp ../esr60/security/nss/lib/ckfw/builtins/certdata.txt security/nss/lib/ckfw/builtins/certdata.txt
cp ../esr60/security/manager/ssl/StaticHPKPins.h security/manager/ssl/StaticHPKPins.h
cp ../esr60/netwerk/dns/effective_tld_names.dat netwerk/dns/effective_tld_names.dat
perl ./104fx_import_esr60_stspreload.pl > security/manager/ssl/nsSTSPreloadList.inc
perl ./104fx_import_shavar_cryptominers.pl > caps/shavar-blocklist.h

