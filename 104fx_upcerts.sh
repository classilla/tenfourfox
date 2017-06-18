#!/bin/csh -f

if (! -e security/manager/ssl/nsSTSPreloadList.inc) then
	echo 'not in the tenfourfox folder, aborting'
endif

set verbose
cp ../esr52/security/nss/lib/ckfw/builtins/certdata.txt security/nss/lib/ckfw/builtins/certdata.txt
cp ../esr52/security/manager/ssl/StaticHPKPins.h security/manager/ssl/StaticHPKPins.h
perl ./104fx_import_esr52_stspreload.pl > security/manager/ssl/nsSTSPreloadList.inc

