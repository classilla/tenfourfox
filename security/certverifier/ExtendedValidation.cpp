/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "ExtendedValidation.h"

#include "cert.h"
#include "certdb.h"
#include "base64.h"
#include "hasht.h"
#include "pkix/pkixtypes.h"
#include "pk11pub.h"
#include "secerr.h"
#include "prerror.h"
#include "prinit.h"

extern PRLogModuleInfo* gPIPNSSLog;

#define CONST_OID static const unsigned char
#define OI(x) { siDEROID, (unsigned char*) x, sizeof x }

// As of TenFourFox FPR9, the oid_tag and cert members are now moved
// into separate arrays so that we can more easily maintain EV roots
// from ESR60+ (TenFourFox issue 512). We can just cut and paste now.

struct nsMyTrustedEVInfo
{
  const char* dotted_oid;
  const char* oid_name; // Set this to null to signal an invalid structure,
                  // (We can't have an empty list, so we'll use a dummy entry)
  const unsigned char ev_root_sha256_fingerprint[SHA256_LENGTH];
  const char* issuer_base64;
  const char* serial_base64;
};

// HOWTO enable additional CA root certificates for EV:
//
// For each combination of "root certificate" and "policy OID",
// one entry must be added to the array named myTrustedEVInfos.
//
// We use the combination of "issuer name" and "serial number" to
// uniquely identify the certificate. In order to avoid problems
// because of encodings when comparing certificates, we don't
// use plain text representation, we rather use the original encoding
// as it can be found in the root certificate (in base64 format).
//
// We can use the NSS utility named "pp" to extract the encoding.
//
// Build standalone NSS including the NSS tools, then run
//   pp -t certificate-identity -i the-cert-filename
//
// You will need the output from sections "Issuer", "Fingerprint (SHA-256)",
// "Issuer DER Base64" and "Serial DER Base64".
//
// The new section consists of 8 lines:
//
// - a comment that should contain the human readable issuer name
//   of the certificate, as printed by the pp tool
// - the EV policy OID that is associated to the EV grant
// - a text description of the EV policy OID. The array can contain
//   multiple entries with the same OID.
//   Please make sure to use the identical OID text description for
//   all entries with the same policy OID (use the text search
//   feature of your text editor to find duplicates).
//   When adding a new policy OID that is not yet contained in the array,
//   please make sure that your new description is different from
//   all the other descriptions (again use the text search feature
//   to be sure).
// - the constant SEC_OID_UNKNOWN
//   (it will be replaced at runtime with another identifier)
// - the SHA-256 fingerprint
// - the "Issuer DER Base64" as printed by the pp tool.
//   Remove all whitespaces. If you use multiple lines, make sure that
//   only the final line will be followed by a comma.
// - the "Serial DER Base64" (as printed by pp)
// - nullptr
//
// After adding an entry, test it locally against the test site that
// has been provided by the CA. Note that you must use a version of NSS
// where the root certificate has already been added and marked as trusted
// for issuing SSL server certificates (at least).
//
// If you are able to connect to the site without certificate errors,
// but you don't see the EV status indicator, then most likely the CA
// has a problem in their infrastructure. The most common problems are
// related to the CA's OCSP infrastructure, either they use an incorrect
// OCSP signing certificate, or OCSP for the intermediate certificates
// isn't working, or OCSP isn't working at all.

#ifdef DEBUG
static const size_t NUM_TEST_EV_ROOTS = 2;
#endif

static struct nsMyTrustedEVInfo myTrustedEVInfos[] = {
  // IMPORTANT! When extending this list, if you add another entry that uses
  // the same dotted_oid as an existing entry, use the same oid_name.
#ifdef DEBUG
  // Debug EV certificates should all use the following OID:
  // 1.3.6.1.4.1.13769.666.666.666.1.500.9.1.
  // (multiple entries with the same OID is ok)
  // If you add or remove debug EV certs you must also modify NUM_TEST_EV_ROOTS
  // so that the correct number of certs are skipped as these debug EV certs
  // are NOT part of the default trust store.
  {
    // This is the PSM xpcshell testing EV certificate. It can be generated
    // using pycert.py and the following specification:
    //
    // issuer:evroot
    // subject:evroot
    // subjectKey:ev
    // issuerKey:ev
    // validity:20150101-20350101
    // extension:basicConstraints:cA,
    // extension:keyUsage:keyCertSign,cRLSign
    //
    // If this ever needs to change, re-generate the certificate and update the
    // following entry with the new fingerprint, issuer, and serial number.
    "1.3.6.1.4.1.13769.666.666.666.1.500.9.1",
    "DEBUGtesting EV OID",
    { 0x70, 0xED, 0xCB, 0x5A, 0xCE, 0x02, 0xC7, 0xC5, 0x0B, 0xA3, 0xD2, 0xD7,
      0xC6, 0xF5, 0x0E, 0x18, 0x02, 0x19, 0x17, 0xF5, 0x48, 0x08, 0x9C, 0xB3,
      0x8E, 0xEF, 0x9A, 0x1A, 0x4D, 0x7F, 0x82, 0x94 },
    "MBExDzANBgNVBAMMBmV2cm9vdA==",
    "IZSHsVgzcvhPgdfrgdMGlpSfMeg=",
  },
  {
    // This is an RSA root with an inadequate key size. It is used to test that
    // minimum key sizes are enforced when verifying for EV. It can be
    // generated using pycert.py and the following specification:
    //
    // issuer:ev_root_rsa_2040
    // subject:ev_root_rsa_2040
    // issuerKey:evRSA2040
    // subjectKey:evRSA2040
    // validity:20150101-20350101
    // extension:basicConstraints:cA,
    // extension:keyUsage:cRLSign,keyCertSign
    //
    // If this ever needs to change, re-generate the certificate and update the
    // following entry with the new fingerprint, issuer, and serial number.
    "1.3.6.1.4.1.13769.666.666.666.1.500.9.1",
    "DEBUGtesting EV OID",
    { 0x40, 0xAB, 0x5D, 0xA5, 0x89, 0x15, 0xA9, 0x4B, 0x82, 0x87, 0xB8, 0xA6,
      0x9A, 0x84, 0xB1, 0xDB, 0x7A, 0x9D, 0xDB, 0xB8, 0x4E, 0xE1, 0x23, 0xE3,
      0xC6, 0x64, 0xE7, 0x50, 0xDC, 0x35, 0x8C, 0x68  },
    "MBsxGTAXBgNVBAMMEGV2X3Jvb3RfcnNhXzIwNDA=",
    "J7nCMgtzNcSPG7jAh3CWzlTGHQg=",
  },
#endif
//
// Paste new EV roots here.
//
  {
    // CN=SwissSign Gold CA - G2,O=SwissSign AG,C=CH
    "2.16.756.1.89.1.2.1.1",
    "SwissSign EV OID",
    { 0x62, 0xDD, 0x0B, 0xE9, 0xB9, 0xF5, 0x0A, 0x16, 0x3E, 0xA0, 0xF8,
      0xE7, 0x5C, 0x05, 0x3B, 0x1E, 0xCA, 0x57, 0xEA, 0x55, 0xC8, 0x68,
      0x8F, 0x64, 0x7C, 0x68, 0x81, 0xF2, 0xC8, 0x35, 0x7B, 0x95 },
    "MEUxCzAJBgNVBAYTAkNIMRUwEwYDVQQKEwxTd2lzc1NpZ24gQUcxHzAdBgNVBAMT"
    "FlN3aXNzU2lnbiBHb2xkIENBIC0gRzI=",
    "ALtAHEP1Xk+w",
  },
  {
    // CN=XRamp Global Certification Authority,O=XRamp Security Services Inc,OU=www.xrampsecurity.com,C=US
    "2.16.840.1.114404.1.1.2.4.1",
    "Trustwave EV OID",
    { 0xCE, 0xCD, 0xDC, 0x90, 0x50, 0x99, 0xD8, 0xDA, 0xDF, 0xC5, 0xB1,
      0xD2, 0x09, 0xB7, 0x37, 0xCB, 0xE2, 0xC1, 0x8C, 0xFB, 0x2C, 0x10,
      0xC0, 0xFF, 0x0B, 0xCF, 0x0D, 0x32, 0x86, 0xFC, 0x1A, 0xA2 },
    "MIGCMQswCQYDVQQGEwJVUzEeMBwGA1UECxMVd3d3LnhyYW1wc2VjdXJpdHkuY29t"
    "MSQwIgYDVQQKExtYUmFtcCBTZWN1cml0eSBTZXJ2aWNlcyBJbmMxLTArBgNVBAMT"
    "JFhSYW1wIEdsb2JhbCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eQ==",
    "UJRs7Bjq1ZxN1ZfvdY+grQ==",
  },
  {
    // CN=SecureTrust CA,O=SecureTrust Corporation,C=US
    "2.16.840.1.114404.1.1.2.4.1",
    "Trustwave EV OID",
    { 0xF1, 0xC1, 0xB5, 0x0A, 0xE5, 0xA2, 0x0D, 0xD8, 0x03, 0x0E, 0xC9,
      0xF6, 0xBC, 0x24, 0x82, 0x3D, 0xD3, 0x67, 0xB5, 0x25, 0x57, 0x59,
      0xB4, 0xE7, 0x1B, 0x61, 0xFC, 0xE9, 0xF7, 0x37, 0x5D, 0x73 },
    "MEgxCzAJBgNVBAYTAlVTMSAwHgYDVQQKExdTZWN1cmVUcnVzdCBDb3Jwb3JhdGlv"
    "bjEXMBUGA1UEAxMOU2VjdXJlVHJ1c3QgQ0E=",
    "DPCOXAgWpa1Cf/DrJxhZ0A==",
  },
  {
    // CN=Secure Global CA,O=SecureTrust Corporation,C=US
    "2.16.840.1.114404.1.1.2.4.1",
    "Trustwave EV OID",
    { 0x42, 0x00, 0xF5, 0x04, 0x3A, 0xC8, 0x59, 0x0E, 0xBB, 0x52, 0x7D,
      0x20, 0x9E, 0xD1, 0x50, 0x30, 0x29, 0xFB, 0xCB, 0xD4, 0x1C, 0xA1,
      0xB5, 0x06, 0xEC, 0x27, 0xF1, 0x5A, 0xDE, 0x7D, 0xAC, 0x69 },
    "MEoxCzAJBgNVBAYTAlVTMSAwHgYDVQQKExdTZWN1cmVUcnVzdCBDb3Jwb3JhdGlv"
    "bjEZMBcGA1UEAxMQU2VjdXJlIEdsb2JhbCBDQQ==",
    "B1YipOjUiolN9BPI8PjqpQ==",
  },
  {
    // CN=COMODO ECC Certification Authority,O=COMODO CA Limited,L=Salford,ST=Greater Manchester,C=GB
    "1.3.6.1.4.1.6449.1.2.1.5.1",
    "Comodo EV OID",
    { 0x17, 0x93, 0x92, 0x7A, 0x06, 0x14, 0x54, 0x97, 0x89, 0xAD, 0xCE,
      0x2F, 0x8F, 0x34, 0xF7, 0xF0, 0xB6, 0x6D, 0x0F, 0x3A, 0xE3, 0xA3,
      0xB8, 0x4D, 0x21, 0xEC, 0x15, 0xDB, 0xBA, 0x4F, 0xAD, 0xC7 },
    "MIGFMQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAw"
    "DgYDVQQHEwdTYWxmb3JkMRowGAYDVQQKExFDT01PRE8gQ0EgTGltaXRlZDErMCkG"
    "A1UEAxMiQ09NT0RPIEVDQyBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eQ==",
    "H0evqmIAcFBUTAGem2OZKg==",
  },
  {
    // CN=COMODO Certification Authority,O=COMODO CA Limited,L=Salford,ST=Greater Manchester,C=GB
    "1.3.6.1.4.1.6449.1.2.1.5.1",
    "Comodo EV OID",
    { 0x0C, 0x2C, 0xD6, 0x3D, 0xF7, 0x80, 0x6F, 0xA3, 0x99, 0xED, 0xE8,
      0x09, 0x11, 0x6B, 0x57, 0x5B, 0xF8, 0x79, 0x89, 0xF0, 0x65, 0x18,
      0xF9, 0x80, 0x8C, 0x86, 0x05, 0x03, 0x17, 0x8B, 0xAF, 0x66 },
    "MIGBMQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAw"
    "DgYDVQQHEwdTYWxmb3JkMRowGAYDVQQKExFDT01PRE8gQ0EgTGltaXRlZDEnMCUG"
    "A1UEAxMeQ09NT0RPIENlcnRpZmljYXRpb24gQXV0aG9yaXR5",
    "ToEtioJl4AsC7j41AkblPQ==",
  },
  {
    // OU=Go Daddy Class 2 Certification Authority,O=\"The Go Daddy Group, Inc.\",C=US
    "2.16.840.1.114413.1.7.23.3",
    "Go Daddy EV OID a",
    { 0xC3, 0x84, 0x6B, 0xF2, 0x4B, 0x9E, 0x93, 0xCA, 0x64, 0x27, 0x4C,
      0x0E, 0xC6, 0x7C, 0x1E, 0xCC, 0x5E, 0x02, 0x4F, 0xFC, 0xAC, 0xD2,
      0xD7, 0x40, 0x19, 0x35, 0x0E, 0x81, 0xFE, 0x54, 0x6A, 0xE4 },
    "MGMxCzAJBgNVBAYTAlVTMSEwHwYDVQQKExhUaGUgR28gRGFkZHkgR3JvdXAsIElu"
    "Yy4xMTAvBgNVBAsTKEdvIERhZGR5IENsYXNzIDIgQ2VydGlmaWNhdGlvbiBBdXRo"
    "b3JpdHk=",
    "AA==",
  },
  {
    // CN=Go Daddy Root Certificate Authority - G2,O="GoDaddy.com, Inc.",L=Scottsdale,ST=Arizona,C=US
    "2.16.840.1.114413.1.7.23.3",
    "Go Daddy EV OID a",
    { 0x45, 0x14, 0x0B, 0x32, 0x47, 0xEB, 0x9C, 0xC8, 0xC5, 0xB4, 0xF0,
      0xD7, 0xB5, 0x30, 0x91, 0xF7, 0x32, 0x92, 0x08, 0x9E, 0x6E, 0x5A,
      0x63, 0xE2, 0x74, 0x9D, 0xD3, 0xAC, 0xA9, 0x19, 0x8E, 0xDA },
    "MIGDMQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2Nv"
    "dHRzZGFsZTEaMBgGA1UEChMRR29EYWRkeS5jb20sIEluYy4xMTAvBgNVBAMTKEdv"
    "IERhZGR5IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzI=",
    "AA==",
  },
  {
    // OU=Starfield Class 2 Certification Authority,O=\"Starfield Technologies, Inc.\",C=US
    "2.16.840.1.114414.1.7.23.3",
    "Go Daddy EV OID b",
    { 0x14, 0x65, 0xFA, 0x20, 0x53, 0x97, 0xB8, 0x76, 0xFA, 0xA6, 0xF0,
      0xA9, 0x95, 0x8E, 0x55, 0x90, 0xE4, 0x0F, 0xCC, 0x7F, 0xAA, 0x4F,
      0xB7, 0xC2, 0xC8, 0x67, 0x75, 0x21, 0xFB, 0x5F, 0xB6, 0x58 },
    "MGgxCzAJBgNVBAYTAlVTMSUwIwYDVQQKExxTdGFyZmllbGQgVGVjaG5vbG9naWVz"
    "LCBJbmMuMTIwMAYDVQQLEylTdGFyZmllbGQgQ2xhc3MgMiBDZXJ0aWZpY2F0aW9u"
    "IEF1dGhvcml0eQ==",
    "AA==",
  },
  {
    // CN=Starfield Root Certificate Authority - G2,O="Starfield Technologies, Inc.",L=Scottsdale,ST=Arizona,C=US
    "2.16.840.1.114414.1.7.23.3",
    "Go Daddy EV OID b",
    { 0x2C, 0xE1, 0xCB, 0x0B, 0xF9, 0xD2, 0xF9, 0xE1, 0x02, 0x99, 0x3F,
      0xBE, 0x21, 0x51, 0x52, 0xC3, 0xB2, 0xDD, 0x0C, 0xAB, 0xDE, 0x1C,
      0x68, 0xE5, 0x31, 0x9B, 0x83, 0x91, 0x54, 0xDB, 0xB7, 0xF5 },
    "MIGPMQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2Nv"
    "dHRzZGFsZTElMCMGA1UEChMcU3RhcmZpZWxkIFRlY2hub2xvZ2llcywgSW5jLjEy"
    "MDAGA1UEAxMpU3RhcmZpZWxkIFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0g"
    "RzI=",
    "AA==",
  },
  {
    // CN=DigiCert High Assurance EV Root CA,OU=www.digicert.com,O=DigiCert Inc,C=US
    "2.16.840.1.114412.2.1",
    "DigiCert EV OID",
    { 0x74, 0x31, 0xE5, 0xF4, 0xC3, 0xC1, 0xCE, 0x46, 0x90, 0x77, 0x4F,
      0x0B, 0x61, 0xE0, 0x54, 0x40, 0x88, 0x3B, 0xA9, 0xA0, 0x1E, 0xD0,
      0x0B, 0xA6, 0xAB, 0xD7, 0x80, 0x6E, 0xD3, 0xB1, 0x18, 0xCF },
    "MGwxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsT"
    "EHd3dy5kaWdpY2VydC5jb20xKzApBgNVBAMTIkRpZ2lDZXJ0IEhpZ2ggQXNzdXJh"
    "bmNlIEVWIFJvb3QgQ0E=",
    "AqxcJmoLQJuPC3nyrkYldw==",
  },
  {
    // CN=QuoVadis Root CA 2,O=QuoVadis Limited,C=BM
    "1.3.6.1.4.1.8024.0.2.100.1.2",
    "Quo Vadis EV OID",
    { 0x85, 0xA0, 0xDD, 0x7D, 0xD7, 0x20, 0xAD, 0xB7, 0xFF, 0x05, 0xF8,
      0x3D, 0x54, 0x2B, 0x20, 0x9D, 0xC7, 0xFF, 0x45, 0x28, 0xF7, 0xD6,
      0x77, 0xB1, 0x83, 0x89, 0xFE, 0xA5, 0xE5, 0xC4, 0x9E, 0x86 },
    "MEUxCzAJBgNVBAYTAkJNMRkwFwYDVQQKExBRdW9WYWRpcyBMaW1pdGVkMRswGQYD"
    "VQQDExJRdW9WYWRpcyBSb290IENBIDI=",
    "BQk=",
  },
  {
    // CN=Entrust Root Certification Authority,OU="(c) 2006 Entrust, Inc.",OU=www.entrust.net/CPS is incorporated by reference,O="Entrust, Inc.",C=US
    "2.16.840.1.114028.10.1.2",
    "Entrust EV OID",
    { 0x73, 0xC1, 0x76, 0x43, 0x4F, 0x1B, 0xC6, 0xD5, 0xAD, 0xF4, 0x5B,
      0x0E, 0x76, 0xE7, 0x27, 0x28, 0x7C, 0x8D, 0xE5, 0x76, 0x16, 0xC1,
      0xE6, 0xE6, 0x14, 0x1A, 0x2B, 0x2C, 0xBC, 0x7D, 0x8E, 0x4C },
    "MIGwMQswCQYDVQQGEwJVUzEWMBQGA1UEChMNRW50cnVzdCwgSW5jLjE5MDcGA1UE"
    "CxMwd3d3LmVudHJ1c3QubmV0L0NQUyBpcyBpbmNvcnBvcmF0ZWQgYnkgcmVmZXJl"
    "bmNlMR8wHQYDVQQLExYoYykgMjAwNiBFbnRydXN0LCBJbmMuMS0wKwYDVQQDEyRF"
    "bnRydXN0IFJvb3QgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHk=",
    "RWtQVA==",
  },
  {
    // CN=Entrust Root Certification Authority - G4,OU="(c) 2015 Entrust, Inc. - for authorized use only",OU=See www.entrust.net/legal-terms,O="Entrust, Inc.",C=US
    "2.16.840.1.114028.10.1.2",
    "Entrust EV OID",
    { 0xDB, 0x35, 0x17, 0xD1, 0xF6, 0x73, 0x2A, 0x2D, 0x5A, 0xB9, 0x7C,
      0x53, 0x3E, 0xC7, 0x07, 0x79, 0xEE, 0x32, 0x70, 0xA6, 0x2F, 0xB4,
      0xAC, 0x42, 0x38, 0x37, 0x24, 0x60, 0xE6, 0xF0, 0x1E, 0x88 },
    "MIG+MQswCQYDVQQGEwJVUzEWMBQGA1UEChMNRW50cnVzdCwgSW5jLjEoMCYGA1UE"
    "CxMfU2VlIHd3dy5lbnRydXN0Lm5ldC9sZWdhbC10ZXJtczE5MDcGA1UECxMwKGMp"
    "IDIwMTUgRW50cnVzdCwgSW5jLiAtIGZvciBhdXRob3JpemVkIHVzZSBvbmx5MTIw"
    "MAYDVQQDEylFbnRydXN0IFJvb3QgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkgLSBH"
    "NA==",
    "ANm1Q3+vqTkPAAAAAFVlrVg=",
  },
  {
    // CN=GlobalSign Root CA,OU=Root CA,O=GlobalSign nv-sa,C=BE
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0xEB, 0xD4, 0x10, 0x40, 0xE4, 0xBB, 0x3E, 0xC7, 0x42, 0xC9, 0xE3,
      0x81, 0xD3, 0x1E, 0xF2, 0xA4, 0x1A, 0x48, 0xB6, 0x68, 0x5C, 0x96,
      0xE7, 0xCE, 0xF3, 0xC1, 0xDF, 0x6C, 0xD4, 0x33, 0x1C, 0x99 },
    "MFcxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMRAwDgYD"
    "VQQLEwdSb290IENBMRswGQYDVQQDExJHbG9iYWxTaWduIFJvb3QgQ0E=",
    "BAAAAAABFUtaw5Q=",
  },
  {
    // CN=GlobalSign,O=GlobalSign,OU=GlobalSign Root CA - R3
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0xCB, 0xB5, 0x22, 0xD7, 0xB7, 0xF1, 0x27, 0xAD, 0x6A, 0x01, 0x13,
      0x86, 0x5B, 0xDF, 0x1C, 0xD4, 0x10, 0x2E, 0x7D, 0x07, 0x59, 0xAF,
      0x63, 0x5A, 0x7C, 0xF4, 0x72, 0x0D, 0xC9, 0x63, 0xC5, 0x3B },
    "MEwxIDAeBgNVBAsTF0dsb2JhbFNpZ24gUm9vdCBDQSAtIFIzMRMwEQYDVQQKEwpH"
    "bG9iYWxTaWduMRMwEQYDVQQDEwpHbG9iYWxTaWdu",
    "BAAAAAABIVhTCKI=",
  },
  {
    // CN=Buypass Class 3 Root CA,O=Buypass AS-983163327,C=NO
    "2.16.578.1.26.1.3.3",
    "Buypass EV OID",
    { 0xED, 0xF7, 0xEB, 0xBC, 0xA2, 0x7A, 0x2A, 0x38, 0x4D, 0x38, 0x7B,
      0x7D, 0x40, 0x10, 0xC6, 0x66, 0xE2, 0xED, 0xB4, 0x84, 0x3E, 0x4C,
      0x29, 0xB4, 0xAE, 0x1D, 0x5B, 0x93, 0x32, 0xE6, 0xB2, 0x4D },
    "ME4xCzAJBgNVBAYTAk5PMR0wGwYDVQQKDBRCdXlwYXNzIEFTLTk4MzE2MzMyNzEg"
    "MB4GA1UEAwwXQnV5cGFzcyBDbGFzcyAzIFJvb3QgQ0E=",
    "Ag==",
  },
  {
    // CN=AffirmTrust Commercial,O=AffirmTrust,C=US
    "1.3.6.1.4.1.34697.2.1",
    "AffirmTrust EV OID a",
    { 0x03, 0x76, 0xAB, 0x1D, 0x54, 0xC5, 0xF9, 0x80, 0x3C, 0xE4, 0xB2,
      0xE2, 0x01, 0xA0, 0xEE, 0x7E, 0xEF, 0x7B, 0x57, 0xB6, 0x36, 0xE8,
      0xA9, 0x3C, 0x9B, 0x8D, 0x48, 0x60, 0xC9, 0x6F, 0x5F, 0xA7 },
    "MEQxCzAJBgNVBAYTAlVTMRQwEgYDVQQKDAtBZmZpcm1UcnVzdDEfMB0GA1UEAwwW"
    "QWZmaXJtVHJ1c3QgQ29tbWVyY2lhbA==",
    "d3cGJyapsXw=",
  },
  {
    // CN=AffirmTrust Networking,O=AffirmTrust,C=US
    "1.3.6.1.4.1.34697.2.2",
    "AffirmTrust EV OID b",
    { 0x0A, 0x81, 0xEC, 0x5A, 0x92, 0x97, 0x77, 0xF1, 0x45, 0x90, 0x4A,
      0xF3, 0x8D, 0x5D, 0x50, 0x9F, 0x66, 0xB5, 0xE2, 0xC5, 0x8F, 0xCD,
      0xB5, 0x31, 0x05, 0x8B, 0x0E, 0x17, 0xF3, 0xF0, 0xB4, 0x1B },
    "MEQxCzAJBgNVBAYTAlVTMRQwEgYDVQQKDAtBZmZpcm1UcnVzdDEfMB0GA1UEAwwW"
    "QWZmaXJtVHJ1c3QgTmV0d29ya2luZw==",
    "fE8EORzUmS0=",
  },
  {
    // CN=AffirmTrust Premium,O=AffirmTrust,C=US
    "1.3.6.1.4.1.34697.2.3",
    "AffirmTrust EV OID c",
    { 0x70, 0xA7, 0x3F, 0x7F, 0x37, 0x6B, 0x60, 0x07, 0x42, 0x48, 0x90,
      0x45, 0x34, 0xB1, 0x14, 0x82, 0xD5, 0xBF, 0x0E, 0x69, 0x8E, 0xCC,
      0x49, 0x8D, 0xF5, 0x25, 0x77, 0xEB, 0xF2, 0xE9, 0x3B, 0x9A },
    "MEExCzAJBgNVBAYTAlVTMRQwEgYDVQQKDAtBZmZpcm1UcnVzdDEcMBoGA1UEAwwT"
    "QWZmaXJtVHJ1c3QgUHJlbWl1bQ==",
    "bYwURrGmCu4=",
  },
  {
    // CN=AffirmTrust Premium ECC,O=AffirmTrust,C=US
    "1.3.6.1.4.1.34697.2.4",
    "AffirmTrust EV OID d",
    { 0xBD, 0x71, 0xFD, 0xF6, 0xDA, 0x97, 0xE4, 0xCF, 0x62, 0xD1, 0x64,
      0x7A, 0xDD, 0x25, 0x81, 0xB0, 0x7D, 0x79, 0xAD, 0xF8, 0x39, 0x7E,
      0xB4, 0xEC, 0xBA, 0x9C, 0x5E, 0x84, 0x88, 0x82, 0x14, 0x23 },
    "MEUxCzAJBgNVBAYTAlVTMRQwEgYDVQQKDAtBZmZpcm1UcnVzdDEgMB4GA1UEAwwX"
    "QWZmaXJtVHJ1c3QgUHJlbWl1bSBFQ0M=",
    "dJclisc/elQ=",
  },
  {
    // CN=Certum Trusted Network CA,OU=Certum Certification Authority,O=Unizeto Technologies S.A.,C=PL
    "1.2.616.1.113527.2.5.1.1",
    "Certum EV OID",
    { 0x5C, 0x58, 0x46, 0x8D, 0x55, 0xF5, 0x8E, 0x49, 0x7E, 0x74, 0x39,
      0x82, 0xD2, 0xB5, 0x00, 0x10, 0xB6, 0xD1, 0x65, 0x37, 0x4A, 0xCF,
      0x83, 0xA7, 0xD4, 0xA3, 0x2D, 0xB7, 0x68, 0xC4, 0x40, 0x8E },
    "MH4xCzAJBgNVBAYTAlBMMSIwIAYDVQQKExlVbml6ZXRvIFRlY2hub2xvZ2llcyBT"
    "LkEuMScwJQYDVQQLEx5DZXJ0dW0gQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxIjAg"
    "BgNVBAMTGUNlcnR1bSBUcnVzdGVkIE5ldHdvcmsgQ0E=",
    "BETA",
  },
  {
    // CN=Certum Trusted Network CA 2,OU=Certum Certification Authority,O=Unizeto Technologies S.A.,C=PL
    "1.2.616.1.113527.2.5.1.1",
    "Certum EV OID",
    { 0xB6, 0x76, 0xF2, 0xED, 0xDA, 0xE8, 0x77, 0x5C, 0xD3, 0x6C, 0xB0,
      0xF6, 0x3C, 0xD1, 0xD4, 0x60, 0x39, 0x61, 0xF4, 0x9E, 0x62, 0x65,
      0xBA, 0x01, 0x3A, 0x2F, 0x03, 0x07, 0xB6, 0xD0, 0xB8, 0x04 },
    "MIGAMQswCQYDVQQGEwJQTDEiMCAGA1UEChMZVW5pemV0byBUZWNobm9sb2dpZXMg"
    "Uy5BLjEnMCUGA1UECxMeQ2VydHVtIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MSQw"
    "IgYDVQQDExtDZXJ0dW0gVHJ1c3RlZCBOZXR3b3JrIENBIDI=",
    "IdbQSk8lD8kyN/yqXhKN6Q==",
  },
  {
    // CN=Izenpe.com,O=IZENPE S.A.,C=ES
    "1.3.6.1.4.1.14777.6.1.1",
    "Izenpe EV OID 1",
    { 0x25, 0x30, 0xCC, 0x8E, 0x98, 0x32, 0x15, 0x02, 0xBA, 0xD9, 0x6F,
      0x9B, 0x1F, 0xBA, 0x1B, 0x09, 0x9E, 0x2D, 0x29, 0x9E, 0x0F, 0x45,
      0x48, 0xBB, 0x91, 0x4F, 0x36, 0x3B, 0xC0, 0xD4, 0x53, 0x1F },
    "MDgxCzAJBgNVBAYTAkVTMRQwEgYDVQQKDAtJWkVOUEUgUy5BLjETMBEGA1UEAwwK"
    "SXplbnBlLmNvbQ==",
    "ALC3WhZIX7/hy/WL1xnmfQ==",
  },
  {
    // CN=Izenpe.com,O=IZENPE S.A.,C=ES
    "1.3.6.1.4.1.14777.6.1.2",
    "Izenpe EV OID 2",
    { 0x25, 0x30, 0xCC, 0x8E, 0x98, 0x32, 0x15, 0x02, 0xBA, 0xD9, 0x6F,
      0x9B, 0x1F, 0xBA, 0x1B, 0x09, 0x9E, 0x2D, 0x29, 0x9E, 0x0F, 0x45,
      0x48, 0xBB, 0x91, 0x4F, 0x36, 0x3B, 0xC0, 0xD4, 0x53, 0x1F },
    "MDgxCzAJBgNVBAYTAkVTMRQwEgYDVQQKDAtJWkVOUEUgUy5BLjETMBEGA1UEAwwK"
    "SXplbnBlLmNvbQ==",
    "ALC3WhZIX7/hy/WL1xnmfQ==",
  },
  {
    // CN=T-TeleSec GlobalRoot Class 3,OU=T-Systems Trust Center,O=T-Systems Enterprise Services GmbH,C=DE
    "1.3.6.1.4.1.7879.13.24.1",
    "T-Systems EV OID",
    { 0xFD, 0x73, 0xDA, 0xD3, 0x1C, 0x64, 0x4F, 0xF1, 0xB4, 0x3B, 0xEF,
      0x0C, 0xCD, 0xDA, 0x96, 0x71, 0x0B, 0x9C, 0xD9, 0x87, 0x5E, 0xCA,
      0x7E, 0x31, 0x70, 0x7A, 0xF3, 0xE9, 0x6D, 0x52, 0x2B, 0xBD },
    "MIGCMQswCQYDVQQGEwJERTErMCkGA1UECgwiVC1TeXN0ZW1zIEVudGVycHJpc2Ug"
    "U2VydmljZXMgR21iSDEfMB0GA1UECwwWVC1TeXN0ZW1zIFRydXN0IENlbnRlcjEl"
    "MCMGA1UEAwwcVC1UZWxlU2VjIEdsb2JhbFJvb3QgQ2xhc3MgMw==",
    "AQ==",
  },
  {
    // CN=TWCA Root Certification Authority,OU=Root CA,O=TAIWAN-CA,C=TW
    "1.3.6.1.4.1.40869.1.1.22.3",
    "TWCA EV OID",
    { 0xBF, 0xD8, 0x8F, 0xE1, 0x10, 0x1C, 0x41, 0xAE, 0x3E, 0x80, 0x1B,
      0xF8, 0xBE, 0x56, 0x35, 0x0E, 0xE9, 0xBA, 0xD1, 0xA6, 0xB9, 0xBD,
      0x51, 0x5E, 0xDC, 0x5C, 0x6D, 0x5B, 0x87, 0x11, 0xAC, 0x44 },
    "MF8xCzAJBgNVBAYTAlRXMRIwEAYDVQQKDAlUQUlXQU4tQ0ExEDAOBgNVBAsMB1Jv"
    "b3QgQ0ExKjAoBgNVBAMMIVRXQ0EgUm9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0"
    "eQ==",
    "AQ==",
  },
  {
    // CN=D-TRUST Root Class 3 CA 2 EV 2009,O=D-Trust GmbH,C=DE
    "1.3.6.1.4.1.4788.2.202.1",
    "D-TRUST EV OID",
    { 0xEE, 0xC5, 0x49, 0x6B, 0x98, 0x8C, 0xE9, 0x86, 0x25, 0xB9, 0x34,
      0x09, 0x2E, 0xEC, 0x29, 0x08, 0xBE, 0xD0, 0xB0, 0xF3, 0x16, 0xC2,
      0xD4, 0x73, 0x0C, 0x84, 0xEA, 0xF1, 0xF3, 0xD3, 0x48, 0x81 },
    "MFAxCzAJBgNVBAYTAkRFMRUwEwYDVQQKDAxELVRydXN0IEdtYkgxKjAoBgNVBAMM"
    "IUQtVFJVU1QgUm9vdCBDbGFzcyAzIENBIDIgRVYgMjAwOQ==",
    "CYP0",
  },
  {
    // CN = TWCA Global Root CA, OU = Root CA, O = TAIWAN-CA, C = TW
    "1.3.6.1.4.1.40869.1.1.22.3",
    "TWCA EV OID",
    { 0x59, 0x76, 0x90, 0x07, 0xF7, 0x68, 0x5D, 0x0F, 0xCD, 0x50, 0x87,
      0x2F, 0x9F, 0x95, 0xD5, 0x75, 0x5A, 0x5B, 0x2B, 0x45, 0x7D, 0x81,
      0xF3, 0x69, 0x2B, 0x61, 0x0A, 0x98, 0x67, 0x2F, 0x0E, 0x1B },
    "MFExCzAJBgNVBAYTAlRXMRIwEAYDVQQKEwlUQUlXQU4tQ0ExEDAOBgNVBAsTB1Jv"
    "b3QgQ0ExHDAaBgNVBAMTE1RXQ0EgR2xvYmFsIFJvb3QgQ0E=",
    "DL4=",
  },
  {
    // CN=Actalis Authentication Root CA,O=Actalis S.p.A./03358520967,L=Milan,C=IT
    "1.3.159.1.17.1",
    "Actalis EV OID",
    { 0x55, 0x92, 0x60, 0x84, 0xEC, 0x96, 0x3A, 0x64, 0xB9, 0x6E, 0x2A,
      0xBE, 0x01, 0xCE, 0x0B, 0xA8, 0x6A, 0x64, 0xFB, 0xFE, 0xBC, 0xC7,
      0xAA, 0xB5, 0xAF, 0xC1, 0x55, 0xB3, 0x7F, 0xD7, 0x60, 0x66 },
    "MGsxCzAJBgNVBAYTAklUMQ4wDAYDVQQHDAVNaWxhbjEjMCEGA1UECgwaQWN0YWxp"
    "cyBTLnAuQS4vMDMzNTg1MjA5NjcxJzAlBgNVBAMMHkFjdGFsaXMgQXV0aGVudGlj"
    "YXRpb24gUm9vdCBDQQ==",
    "VwoRl0LE48w=",
  },
  {
    // CN=DigiCert Assured ID Root G2,OU=www.digicert.com,O=DigiCert Inc,C=US
    "2.16.840.1.114412.2.1",
    "DigiCert EV OID",
    { 0x7D, 0x05, 0xEB, 0xB6, 0x82, 0x33, 0x9F, 0x8C, 0x94, 0x51, 0xEE,
      0x09, 0x4E, 0xEB, 0xFE, 0xFA, 0x79, 0x53, 0xA1, 0x14, 0xED, 0xB2,
      0xF4, 0x49, 0x49, 0x45, 0x2F, 0xAB, 0x7D, 0x2F, 0xC1, 0x85 },
    "MGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsT"
    "EHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQg"
    "Um9vdCBHMg==",
    "C5McOtY5Z+pnI7/Dr5r0Sw==",
  },
  {
    // CN=DigiCert Assured ID Root G3,OU=www.digicert.com,O=DigiCert Inc,C=US
    "2.16.840.1.114412.2.1",
    "DigiCert EV OID",
    { 0x7E, 0x37, 0xCB, 0x8B, 0x4C, 0x47, 0x09, 0x0C, 0xAB, 0x36, 0x55,
      0x1B, 0xA6, 0xF4, 0x5D, 0xB8, 0x40, 0x68, 0x0F, 0xBA, 0x16, 0x6A,
      0x95, 0x2D, 0xB1, 0x00, 0x71, 0x7F, 0x43, 0x05, 0x3F, 0xC2 },
    "MGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsT"
    "EHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQg"
    "Um9vdCBHMw==",
    "C6Fa+h3foLVJRK/NJKBs7A==",
  },
  {
    // CN=DigiCert Global Root G2,OU=www.digicert.com,O=DigiCert Inc,C=US
    "2.16.840.1.114412.2.1",
    "DigiCert EV OID",
    { 0xCB, 0x3C, 0xCB, 0xB7, 0x60, 0x31, 0xE5, 0xE0, 0x13, 0x8F, 0x8D,
      0xD3, 0x9A, 0x23, 0xF9, 0xDE, 0x47, 0xFF, 0xC3, 0x5E, 0x43, 0xC1,
      0x14, 0x4C, 0xEA, 0x27, 0xD4, 0x6A, 0x5A, 0xB1, 0xCB, 0x5F },
    "MGExCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsT"
    "EHd3dy5kaWdpY2VydC5jb20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290"
    "IEcy",
    "Azrx5qcRqaC7KGSxHQn65Q==",
  },
  {
    // CN=DigiCert Global Root G3,OU=www.digicert.com,O=DigiCert Inc,C=US
    "2.16.840.1.114412.2.1",
    "DigiCert EV OID",
    { 0x31, 0xAD, 0x66, 0x48, 0xF8, 0x10, 0x41, 0x38, 0xC7, 0x38, 0xF3,
      0x9E, 0xA4, 0x32, 0x01, 0x33, 0x39, 0x3E, 0x3A, 0x18, 0xCC, 0x02,
      0x29, 0x6E, 0xF9, 0x7C, 0x2A, 0xC9, 0xEF, 0x67, 0x31, 0xD0 },
    "MGExCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsT"
    "EHd3dy5kaWdpY2VydC5jb20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290"
    "IEcz",
    "BVVWvPJepDU1w6QP1atFcg==",
  },
  {
    // CN=DigiCert Trusted Root G4,OU=www.digicert.com,O=DigiCert Inc,C=US
    "2.16.840.1.114412.2.1",
    "DigiCert EV OID",
    { 0x55, 0x2F, 0x7B, 0xDC, 0xF1, 0xA7, 0xAF, 0x9E, 0x6C, 0xE6, 0x72,
      0x01, 0x7F, 0x4F, 0x12, 0xAB, 0xF7, 0x72, 0x40, 0xC7, 0x8E, 0x76,
      0x1A, 0xC2, 0x03, 0xD1, 0xD9, 0xD2, 0x0A, 0xC8, 0x99, 0x88 },
    "MGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsT"
    "EHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9v"
    "dCBHNA==",
    "BZsbV56OITLiOQe9p3d1XA==",
  },
  {
    // CN=DigiCert TLS RSA4096 Root G5,O="DigiCert, Inc.",C=US
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x37, 0x1A, 0x00, 0xDC, 0x05, 0x33, 0xB3, 0x72, 0x1A, 0x7E, 0xEB,
      0x40, 0xE8, 0x41, 0x9E, 0x70, 0x79, 0x9D, 0x2B, 0x0A, 0x0F, 0x2C,
      0x1D, 0x80, 0x69, 0x31, 0x65, 0xF7, 0xCE, 0xC4, 0xAD, 0x75 },
    "ME0xCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjElMCMGA1UE"
    "AxMcRGlnaUNlcnQgVExTIFJTQTQwOTYgUm9vdCBHNQ==",
    "CPm0eKj6ftpqMzeJ3nzPig==",
  },
  {
    // CN=DigiCert TLS ECC P384 Root G5,O="DigiCert, Inc.",C=US
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x01, 0x8E, 0x13, 0xF0, 0x77, 0x25, 0x32, 0xCF, 0x80, 0x9B, 0xD1,
      0xB1, 0x72, 0x81, 0x86, 0x72, 0x83, 0xFC, 0x48, 0xC6, 0xE1, 0x3B,
      0xE9, 0xC6, 0x98, 0x12, 0x85, 0x4A, 0x49, 0x0C, 0x1B, 0x05 },
    "ME4xCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjEmMCQGA1UE"
    "AxMdRGlnaUNlcnQgVExTIEVDQyBQMzg0IFJvb3QgRzU=",
    "CeCTZaz32ci5PhwLBCou8w==",
  },
  {
    // CN=QuoVadis Root CA 2 G3,O=QuoVadis Limited,C=BM
    "1.3.6.1.4.1.8024.0.2.100.1.2",
    "QuoVadis EV OID",
    { 0x8F, 0xE4, 0xFB, 0x0A, 0xF9, 0x3A, 0x4D, 0x0D, 0x67, 0xDB, 0x0B,
      0xEB, 0xB2, 0x3E, 0x37, 0xC7, 0x1B, 0xF3, 0x25, 0xDC, 0xBC, 0xDD,
      0x24, 0x0E, 0xA0, 0x4D, 0xAF, 0x58, 0xB4, 0x7E, 0x18, 0x40 },
    "MEgxCzAJBgNVBAYTAkJNMRkwFwYDVQQKExBRdW9WYWRpcyBMaW1pdGVkMR4wHAYD"
    "VQQDExVRdW9WYWRpcyBSb290IENBIDIgRzM=",
    "RFc0JFuBiZs18s64KztbpybwdSg=",
  },
  {
    // CN=COMODO RSA Certification Authority,O=COMODO CA Limited,L=Salford,ST=Greater Manchester,C=GB
    "1.3.6.1.4.1.6449.1.2.1.5.1",
    "Comodo EV OID",
    { 0x52, 0xF0, 0xE1, 0xC4, 0xE5, 0x8E, 0xC6, 0x29, 0x29, 0x1B, 0x60,
      0x31, 0x7F, 0x07, 0x46, 0x71, 0xB8, 0x5D, 0x7E, 0xA8, 0x0D, 0x5B,
      0x07, 0x27, 0x34, 0x63, 0x53, 0x4B, 0x32, 0xB4, 0x02, 0x34 },
    "MIGFMQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAw"
    "DgYDVQQHEwdTYWxmb3JkMRowGAYDVQQKExFDT01PRE8gQ0EgTGltaXRlZDErMCkG"
    "A1UEAxMiQ09NT0RPIFJTQSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eQ==",
    "TKr5yttjb+Af907YWwOGnQ==",
  },
  {
    // CN=USERTrust RSA Certification Authority,O=The USERTRUST Network,L=Jersey City,ST=New Jersey,C=US
    "1.3.6.1.4.1.6449.1.2.1.5.1",
    "Comodo EV OID",
    { 0xE7, 0x93, 0xC9, 0xB0, 0x2F, 0xD8, 0xAA, 0x13, 0xE2, 0x1C, 0x31,
      0x22, 0x8A, 0xCC, 0xB0, 0x81, 0x19, 0x64, 0x3B, 0x74, 0x9C, 0x89,
      0x89, 0x64, 0xB1, 0x74, 0x6D, 0x46, 0xC3, 0xD4, 0xCB, 0xD2 },
    "MIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKTmV3IEplcnNleTEUMBIGA1UEBxML"
    "SmVyc2V5IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEuMCwG"
    "A1UEAxMlVVNFUlRydXN0IFJTQSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eQ==",
    "Af1tMPyjylGoG7xkDjUDLQ==",
  },
  {
    // CN=USERTrust ECC Certification Authority,O=The USERTRUST Network,L=Jersey City,ST=New Jersey,C=US
    "1.3.6.1.4.1.6449.1.2.1.5.1",
    "Comodo EV OID",
    { 0x4F, 0xF4, 0x60, 0xD5, 0x4B, 0x9C, 0x86, 0xDA, 0xBF, 0xBC, 0xFC,
      0x57, 0x12, 0xE0, 0x40, 0x0D, 0x2B, 0xED, 0x3F, 0xBC, 0x4D, 0x4F,
      0xBD, 0xAA, 0x86, 0xE0, 0x6A, 0xDC, 0xD2, 0xA9, 0xAD, 0x7A },
    "MIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKTmV3IEplcnNleTEUMBIGA1UEBxML"
    "SmVyc2V5IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEuMCwG"
    "A1UEAxMlVVNFUlRydXN0IEVDQyBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eQ==",
    "XIuZxVqUxdJxVt7NiYDMJg==",
  },
  {
    // CN=GlobalSign,O=GlobalSign,OU=GlobalSign ECC Root CA - R5
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x17, 0x9F, 0xBC, 0x14, 0x8A, 0x3D, 0xD0, 0x0F, 0xD2, 0x4E, 0xA1,
      0x34, 0x58, 0xCC, 0x43, 0xBF, 0xA7, 0xF5, 0x9C, 0x81, 0x82, 0xD7,
      0x83, 0xA5, 0x13, 0xF6, 0xEB, 0xEC, 0x10, 0x0C, 0x89, 0x24 },
    "MFAxJDAiBgNVBAsTG0dsb2JhbFNpZ24gRUNDIFJvb3QgQ0EgLSBSNTETMBEGA1UE"
    "ChMKR2xvYmFsU2lnbjETMBEGA1UEAxMKR2xvYmFsU2lnbg==",
    "YFlJ4CYuu1X5CneKcflK2Gw=",
  },
  {
    // CN=GlobalSign,O=GlobalSign,OU=GlobalSign Root CA - R6
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x2C, 0xAB, 0xEA, 0xFE, 0x37, 0xD0, 0x6C, 0xA2, 0x2A, 0xBA, 0x73,
      0x91, 0xC0, 0x03, 0x3D, 0x25, 0x98, 0x29, 0x52, 0xC4, 0x53, 0x64,
      0x73, 0x49, 0x76, 0x3A, 0x3A, 0xB5, 0xAD, 0x6C, 0xCF, 0x69 },
    "MEwxIDAeBgNVBAsTF0dsb2JhbFNpZ24gUm9vdCBDQSAtIFI2MRMwEQYDVQQKEwpH"
    "bG9iYWxTaWduMRMwEQYDVQQDEwpHbG9iYWxTaWdu",
    "Rea7A4Mzw4VlSOb/RVE=",
  },
  {
    // CN=Entrust.net Certification Authority (2048),OU=(c) 1999 Entrust.net Limited,OU=www.entrust.net/CPS_2048 incorp. by ref. (limits liab.),O=Entrust.net
    "2.16.840.1.114028.10.1.2",
    "Entrust EV OID",
    { 0x6D, 0xC4, 0x71, 0x72, 0xE0, 0x1C, 0xBC, 0xB0, 0xBF, 0x62, 0x58,
      0x0D, 0x89, 0x5F, 0xE2, 0xB8, 0xAC, 0x9A, 0xD4, 0xF8, 0x73, 0x80,
      0x1E, 0x0C, 0x10, 0xB9, 0xC8, 0x37, 0xD2, 0x1E, 0xB1, 0x77 },
    "MIG0MRQwEgYDVQQKEwtFbnRydXN0Lm5ldDFAMD4GA1UECxQ3d3d3LmVudHJ1c3Qu"
    "bmV0L0NQU18yMDQ4IGluY29ycC4gYnkgcmVmLiAobGltaXRzIGxpYWIuKTElMCMG"
    "A1UECxMcKGMpIDE5OTkgRW50cnVzdC5uZXQgTGltaXRlZDEzMDEGA1UEAxMqRW50"
    "cnVzdC5uZXQgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkgKDIwNDgp",
    "OGPe+A==",
  },
  {
    // CN=Entrust Root Certification Authority - G2,OU="(c) 2009 Entrust, Inc. - for authorized use only",OU=See www.entrust.net/legal-terms,O="Entrust, Inc.",C=US
    "2.16.840.1.114028.10.1.2",
    "Entrust EV OID",
    { 0x43, 0xDF, 0x57, 0x74, 0xB0, 0x3E, 0x7F, 0xEF, 0x5F, 0xE4, 0x0D,
      0x93, 0x1A, 0x7B, 0xED, 0xF1, 0xBB, 0x2E, 0x6B, 0x42, 0x73, 0x8C,
      0x4E, 0x6D, 0x38, 0x41, 0x10, 0x3D, 0x3A, 0xA7, 0xF3, 0x39 },
    "MIG+MQswCQYDVQQGEwJVUzEWMBQGA1UEChMNRW50cnVzdCwgSW5jLjEoMCYGA1UE"
    "CxMfU2VlIHd3dy5lbnRydXN0Lm5ldC9sZWdhbC10ZXJtczE5MDcGA1UECxMwKGMp"
    "IDIwMDkgRW50cnVzdCwgSW5jLiAtIGZvciBhdXRob3JpemVkIHVzZSBvbmx5MTIw"
    "MAYDVQQDEylFbnRydXN0IFJvb3QgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkgLSBH"
    "Mg==",
    "SlOMKA==",
  },
  {
    // CN=Entrust Root Certification Authority - EC1,OU="(c) 2012 Entrust, Inc. - for authorized use only",OU=See www.entrust.net/legal-terms,O="Entrust, Inc.",C=US
    "2.16.840.1.114028.10.1.2",
    "Entrust EV OID",
    { 0x02, 0xED, 0x0E, 0xB2, 0x8C, 0x14, 0xDA, 0x45, 0x16, 0x5C, 0x56,
      0x67, 0x91, 0x70, 0x0D, 0x64, 0x51, 0xD7, 0xFB, 0x56, 0xF0, 0xB2,
      0xAB, 0x1D, 0x3B, 0x8E, 0xB0, 0x70, 0xE5, 0x6E, 0xDF, 0xF5 },
    "MIG/MQswCQYDVQQGEwJVUzEWMBQGA1UEChMNRW50cnVzdCwgSW5jLjEoMCYGA1UE"
    "CxMfU2VlIHd3dy5lbnRydXN0Lm5ldC9sZWdhbC10ZXJtczE5MDcGA1UECxMwKGMp"
    "IDIwMTIgRW50cnVzdCwgSW5jLiAtIGZvciBhdXRob3JpemVkIHVzZSBvbmx5MTMw"
    "MQYDVQQDEypFbnRydXN0IFJvb3QgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkgLSBF"
    "QzE=",
    "AKaLeSkAAAAAUNCR+Q==",
  },
  {
    // CN=CFCA EV ROOT,O=China Financial Certification Authority,C=CN
    "2.16.156.112554.3",
    "CFCA EV OID",
    { 0x5C, 0xC3, 0xD7, 0x8E, 0x4E, 0x1D, 0x5E, 0x45, 0x54, 0x7A, 0x04,
      0xE6, 0x87, 0x3E, 0x64, 0xF9, 0x0C, 0xF9, 0x53, 0x6D, 0x1C, 0xCC,
      0x2E, 0xF8, 0x00, 0xF3, 0x55, 0xC4, 0xC5, 0xFD, 0x70, 0xFD },
    "MFYxCzAJBgNVBAYTAkNOMTAwLgYDVQQKDCdDaGluYSBGaW5hbmNpYWwgQ2VydGlm"
    "aWNhdGlvbiBBdXRob3JpdHkxFTATBgNVBAMMDENGQ0EgRVYgUk9PVA==",
    "GErM1g==",
  },
  {
    // OU=Security Communication RootCA2,O="SECOM Trust Systems CO.,LTD.",C=JP
    "1.2.392.200091.100.721.1",
    "SECOM EV OID",
    { 0x51, 0x3B, 0x2C, 0xEC, 0xB8, 0x10, 0xD4, 0xCD, 0xE5, 0xDD, 0x85,
      0x39, 0x1A, 0xDF, 0xC6, 0xC2, 0xDD, 0x60, 0xD8, 0x7B, 0xB7, 0x36,
      0xD2, 0xB5, 0x21, 0x48, 0x4A, 0xA4, 0x7A, 0x0E, 0xBE, 0xF6 },
    "MF0xCzAJBgNVBAYTAkpQMSUwIwYDVQQKExxTRUNPTSBUcnVzdCBTeXN0ZW1zIENP"
    "LixMVEQuMScwJQYDVQQLEx5TZWN1cml0eSBDb21tdW5pY2F0aW9uIFJvb3RDQTI=",
    "AA==",
  },
  {
    // CN=OISTE WISeKey Global Root GB CA,OU=OISTE Foundation Endorsed,O=WISeKey,C=CH
    "2.16.756.5.14.7.4.8",
    "WISeKey EV OID",
    { 0x6B, 0x9C, 0x08, 0xE8, 0x6E, 0xB0, 0xF7, 0x67, 0xCF, 0xAD, 0x65,
      0xCD, 0x98, 0xB6, 0x21, 0x49, 0xE5, 0x49, 0x4A, 0x67, 0xF5, 0x84,
      0x5E, 0x7B, 0xD1, 0xED, 0x01, 0x9F, 0x27, 0xB8, 0x6B, 0xD6 },
    "MG0xCzAJBgNVBAYTAkNIMRAwDgYDVQQKEwdXSVNlS2V5MSIwIAYDVQQLExlPSVNU"
    "RSBGb3VuZGF0aW9uIEVuZG9yc2VkMSgwJgYDVQQDEx9PSVNURSBXSVNlS2V5IEds"
    "b2JhbCBSb290IEdCIENB",
    "drEgUnTwhYdGs/gjGvbCwA==",
  },
  {
    // CN=Amazon Root CA 1,O=Amazon,C=US
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x8E, 0xCD, 0xE6, 0x88, 0x4F, 0x3D, 0x87, 0xB1, 0x12, 0x5B, 0xA3,
      0x1A, 0xC3, 0xFC, 0xB1, 0x3D, 0x70, 0x16, 0xDE, 0x7F, 0x57, 0xCC,
      0x90, 0x4F, 0xE1, 0xCB, 0x97, 0xC6, 0xAE, 0x98, 0x19, 0x6E },
    "MDkxCzAJBgNVBAYTAlVTMQ8wDQYDVQQKEwZBbWF6b24xGTAXBgNVBAMTEEFtYXpv"
    "biBSb290IENBIDE=",
    "Bmyfz5m/jAo54vB4ikPmljZbyg==",
  },
  {
    // CN=Amazon Root CA 2,O=Amazon,C=US
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x1B, 0xA5, 0xB2, 0xAA, 0x8C, 0x65, 0x40, 0x1A, 0x82, 0x96, 0x01,
      0x18, 0xF8, 0x0B, 0xEC, 0x4F, 0x62, 0x30, 0x4D, 0x83, 0xCE, 0xC4,
      0x71, 0x3A, 0x19, 0xC3, 0x9C, 0x01, 0x1E, 0xA4, 0x6D, 0xB4 },
    "MDkxCzAJBgNVBAYTAlVTMQ8wDQYDVQQKEwZBbWF6b24xGTAXBgNVBAMTEEFtYXpv"
    "biBSb290IENBIDI=",
    "Bmyf0pY1hp8KD+WGePhbJruKNw==",
  },
  {
    // CN=Amazon Root CA 3,O=Amazon,C=US
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x18, 0xCE, 0x6C, 0xFE, 0x7B, 0xF1, 0x4E, 0x60, 0xB2, 0xE3, 0x47,
      0xB8, 0xDF, 0xE8, 0x68, 0xCB, 0x31, 0xD0, 0x2E, 0xBB, 0x3A, 0xDA,
      0x27, 0x15, 0x69, 0xF5, 0x03, 0x43, 0xB4, 0x6D, 0xB3, 0xA4 },
    "MDkxCzAJBgNVBAYTAlVTMQ8wDQYDVQQKEwZBbWF6b24xGTAXBgNVBAMTEEFtYXpv"
    "biBSb290IENBIDM=",
    "Bmyf1XSXNmY/Owua2eiedgPySg==",
  },
  {
    // CN=Amazon Root CA 4,O=Amazon,C=US
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0xE3, 0x5D, 0x28, 0x41, 0x9E, 0xD0, 0x20, 0x25, 0xCF, 0xA6, 0x90,
      0x38, 0xCD, 0x62, 0x39, 0x62, 0x45, 0x8D, 0xA5, 0xC6, 0x95, 0xFB,
      0xDE, 0xA3, 0xC2, 0x2B, 0x0B, 0xFB, 0x25, 0x89, 0x70, 0x92 },
    "MDkxCzAJBgNVBAYTAlVTMQ8wDQYDVQQKEwZBbWF6b24xGTAXBgNVBAMTEEFtYXpv"
    "biBSb290IENBIDQ=",
    "Bmyf18G7EEwpQ+Vxe3ssyBrBDg==",
  },
  {
    // CN=Starfield Services Root Certificate Authority - G2,O="Starfield Technologies, Inc.",L=Scottsdale,ST=Arizona,C=US
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x56, 0x8D, 0x69, 0x05, 0xA2, 0xC8, 0x87, 0x08, 0xA4, 0xB3, 0x02,
      0x51, 0x90, 0xED, 0xCF, 0xED, 0xB1, 0x97, 0x4A, 0x60, 0x6A, 0x13,
      0xC6, 0xE5, 0x29, 0x0F, 0xCB, 0x2A, 0xE6, 0x3E, 0xDA, 0xB5 },
    "MIGYMQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2Nv"
    "dHRzZGFsZTElMCMGA1UEChMcU3RhcmZpZWxkIFRlY2hub2xvZ2llcywgSW5jLjE7"
    "MDkGA1UEAxMyU3RhcmZpZWxkIFNlcnZpY2VzIFJvb3QgQ2VydGlmaWNhdGUgQXV0"
    "aG9yaXR5IC0gRzI=",
    "AA==",
  },
  {
    // CN=GDCA TrustAUTH R5 ROOT,O="GUANG DONG CERTIFICATE AUTHORITY CO.,LTD.",C=CN
    "1.2.156.112559.1.1.6.1",
    "GDCA EV OID",
    { 0xBF, 0xFF, 0x8F, 0xD0, 0x44, 0x33, 0x48, 0x7D, 0x6A, 0x8A, 0xA6,
      0x0C, 0x1A, 0x29, 0x76, 0x7A, 0x9F, 0xC2, 0xBB, 0xB0, 0x5E, 0x42,
      0x0F, 0x71, 0x3A, 0x13, 0xB9, 0x92, 0x89, 0x1D, 0x38, 0x93 },
    "MGIxCzAJBgNVBAYTAkNOMTIwMAYDVQQKDClHVUFORyBET05HIENFUlRJRklDQVRF"
    "IEFVVEhPUklUWSBDTy4sTFRELjEfMB0GA1UEAwwWR0RDQSBUcnVzdEFVVEggUjUg"
    "Uk9PVA==",
    "fQmX/vBH6no=",
  },
  {
    // CN=SSL.com EV Root Certification Authority ECC,O=SSL Corporation,L=Houston,ST=Texas,C=US
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x22, 0xA2, 0xC1, 0xF7, 0xBD, 0xED, 0x70, 0x4C, 0xC1, 0xE7, 0x01,
      0xB5, 0xF4, 0x08, 0xC3, 0x10, 0x88, 0x0F, 0xE9, 0x56, 0xB5, 0xDE,
      0x2A, 0x4A, 0x44, 0xF9, 0x9C, 0x87, 0x3A, 0x25, 0xA7, 0xC8 },
    "MH8xCzAJBgNVBAYTAlVTMQ4wDAYDVQQIDAVUZXhhczEQMA4GA1UEBwwHSG91c3Rv"
    "bjEYMBYGA1UECgwPU1NMIENvcnBvcmF0aW9uMTQwMgYDVQQDDCtTU0wuY29tIEVW"
    "IFJvb3QgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkgRUND",
    "LCmcWxbtBZU=",
  },
  {
    // CN=SSL.com EV Root Certification Authority RSA R2,O=SSL Corporation,L=Houston,ST=Texas,C=US
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x2E, 0x7B, 0xF1, 0x6C, 0xC2, 0x24, 0x85, 0xA7, 0xBB, 0xE2, 0xAA,
      0x86, 0x96, 0x75, 0x07, 0x61, 0xB0, 0xAE, 0x39, 0xBE, 0x3B, 0x2F,
      0xE9, 0xD0, 0xCC, 0x6D, 0x4E, 0xF7, 0x34, 0x91, 0x42, 0x5C },
    "MIGCMQswCQYDVQQGEwJVUzEOMAwGA1UECAwFVGV4YXMxEDAOBgNVBAcMB0hvdXN0"
    "b24xGDAWBgNVBAoMD1NTTCBDb3Jwb3JhdGlvbjE3MDUGA1UEAwwuU1NMLmNvbSBF"
    "ViBSb290IENlcnRpZmljYXRpb24gQXV0aG9yaXR5IFJTQSBSMg==",
    "VrYpzTS8ePY=",
  },
  {
    // CN=SSL.com TLS ECC Root CA 2022,O=SSL Corporation,C=US
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0xC3, 0x2F, 0xFD, 0x9F, 0x46, 0xF9, 0x36, 0xD1, 0x6C, 0x36, 0x73,
      0x99, 0x09, 0x59, 0x43, 0x4B, 0x9A, 0xD6, 0x0A, 0xAF, 0xBB, 0x9E,
      0x7C, 0xF3, 0x36, 0x54, 0xF1, 0x44, 0xCC, 0x1B, 0xA1, 0x43 },
    "ME4xCzAJBgNVBAYTAlVTMRgwFgYDVQQKDA9TU0wgQ29ycG9yYXRpb24xJTAjBgNV"
    "BAMMHFNTTC5jb20gVExTIEVDQyBSb290IENBIDIwMjI=",
    "FAP1q/s3ixdAW+JDsqXRxA==",
  },
  {
    // CN=SSL.com TLS RSA Root CA 2022,O=SSL Corporation,C=US
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x8F, 0xAF, 0x7D, 0x2E, 0x2C, 0xB4, 0x70, 0x9B, 0xB8, 0xE0, 0xB3,
      0x36, 0x66, 0xBF, 0x75, 0xA5, 0xDD, 0x45, 0xB5, 0xDE, 0x48, 0x0F,
      0x8E, 0xA8, 0xD4, 0xBF, 0xE6, 0xBE, 0xBC, 0x17, 0xF2, 0xED },
    "ME4xCzAJBgNVBAYTAlVTMRgwFgYDVQQKDA9TU0wgQ29ycG9yYXRpb24xJTAjBgNV"
    "BAMMHFNTTC5jb20gVExTIFJTQSBSb290IENBIDIwMjI=",
    "b77arXO9CEDii02+1PdbkQ==",
  },
  {
    // CN=UCA Extended Validation Root,O=UniTrust,C=CN
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0xD4, 0x3A, 0xF9, 0xB3, 0x54, 0x73, 0x75, 0x5C, 0x96, 0x84, 0xFC,
      0x06, 0xD7, 0xD8, 0xCB, 0x70, 0xEE, 0x5C, 0x28, 0xE7, 0x73, 0xFB,
      0x29, 0x4E, 0xB4, 0x1E, 0xE7, 0x17, 0x22, 0x92, 0x4D, 0x24 },
    "MEcxCzAJBgNVBAYTAkNOMREwDwYDVQQKDAhVbmlUcnVzdDElMCMGA1UEAwwcVUNB"
    "IEV4dGVuZGVkIFZhbGlkYXRpb24gUm9vdA==",
    "T9Irj/VkyDOeTzRYZiNwYA==",
  },
  {
    // CN=Hongkong Post Root CA 3,O=Hongkong Post,L=Hong Kong,ST=Hong Kong,C=HK
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x5A, 0x2F, 0xC0, 0x3F, 0x0C, 0x83, 0xB0, 0x90, 0xBB, 0xFA, 0x40,
      0x60, 0x4B, 0x09, 0x88, 0x44, 0x6C, 0x76, 0x36, 0x18, 0x3D, 0xF9,
      0x84, 0x6E, 0x17, 0x10, 0x1A, 0x44, 0x7F, 0xB8, 0xEF, 0xD6 },
    "MG8xCzAJBgNVBAYTAkhLMRIwEAYDVQQIEwlIb25nIEtvbmcxEjAQBgNVBAcTCUhv"
    "bmcgS29uZzEWMBQGA1UEChMNSG9uZ2tvbmcgUG9zdDEgMB4GA1UEAxMXSG9uZ2tv"
    "bmcgUG9zdCBSb290IENBIDM=",
    "CBZfikyl7ADJk0DfxMauI7gcWqQ=",
  },
  {
    // CN=emSign Root CA - G1,O=eMudhra Technologies Limited,OU=emSign PKI,C=IN
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x40, 0xF6, 0xAF, 0x03, 0x46, 0xA9, 0x9A, 0xA1, 0xCD, 0x1D, 0x55,
      0x5A, 0x4E, 0x9C, 0xCE, 0x62, 0xC7, 0xF9, 0x63, 0x46, 0x03, 0xEE,
      0x40, 0x66, 0x15, 0x83, 0x3D, 0xC8, 0xC8, 0xD0, 0x03, 0x67 },
    "MGcxCzAJBgNVBAYTAklOMRMwEQYDVQQLEwplbVNpZ24gUEtJMSUwIwYDVQQKExxl"
    "TXVkaHJhIFRlY2hub2xvZ2llcyBMaW1pdGVkMRwwGgYDVQQDExNlbVNpZ24gUm9v"
    "dCBDQSAtIEcx",
    "MfXkYgxsWO3W2A==",
  },
  {
    // CN=emSign ECC Root CA - G3,O=eMudhra Technologies Limited,OU=emSign PKI,C=IN
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x86, 0xA1, 0xEC, 0xBA, 0x08, 0x9C, 0x4A, 0x8D, 0x3B, 0xBE, 0x27,
      0x34, 0xC6, 0x12, 0xBA, 0x34, 0x1D, 0x81, 0x3E, 0x04, 0x3C, 0xF9,
      0xE8, 0xA8, 0x62, 0xCD, 0x5C, 0x57, 0xA3, 0x6B, 0xBE, 0x6B },
    "MGsxCzAJBgNVBAYTAklOMRMwEQYDVQQLEwplbVNpZ24gUEtJMSUwIwYDVQQKExxl"
    "TXVkaHJhIFRlY2hub2xvZ2llcyBMaW1pdGVkMSAwHgYDVQQDExdlbVNpZ24gRUND"
    "IFJvb3QgQ0EgLSBHMw==",
    "PPYHqWhwDtqLhA==",
  },
  {
    // CN=emSign Root CA - C1,O=eMudhra Inc,OU=emSign PKI,C=US
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x12, 0x56, 0x09, 0xAA, 0x30, 0x1D, 0xA0, 0xA2, 0x49, 0xB9, 0x7A,
      0x82, 0x39, 0xCB, 0x6A, 0x34, 0x21, 0x6F, 0x44, 0xDC, 0xAC, 0x9F,
      0x39, 0x54, 0xB1, 0x42, 0x92, 0xF2, 0xE8, 0xC8, 0x60, 0x8F },
    "MFYxCzAJBgNVBAYTAlVTMRMwEQYDVQQLEwplbVNpZ24gUEtJMRQwEgYDVQQKEwtl"
    "TXVkaHJhIEluYzEcMBoGA1UEAxMTZW1TaWduIFJvb3QgQ0EgLSBDMQ==",
    "AK7PALrEzzL4Q7I=",
    },
  {
    // CN=emSign ECC Root CA - C3,O=eMudhra Inc,OU=emSign PKI,C=US
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0xBC, 0x4D, 0x80, 0x9B, 0x15, 0x18, 0x9D, 0x78, 0xDB, 0x3E, 0x1D,
      0x8C, 0xF4, 0xF9, 0x72, 0x6A, 0x79, 0x5D, 0xA1, 0x64, 0x3C, 0xA5,
      0xF1, 0x35, 0x8E, 0x1D, 0xDB, 0x0E, 0xDC, 0x0D, 0x7E, 0xB3 },
    "MFoxCzAJBgNVBAYTAlVTMRMwEQYDVQQLEwplbVNpZ24gUEtJMRQwEgYDVQQKEwtl"
    "TXVkaHJhIEluYzEgMB4GA1UEAxMXZW1TaWduIEVDQyBSb290IENBIC0gQzM=",
    "e3G2gla4EnycqA==",
  },
  {
    // OU=certSIGN ROOT CA G2,O=CERTSIGN SA,C=RO
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x65, 0x7C, 0xFE, 0x2F, 0xA7, 0x3F, 0xAA, 0x38, 0x46, 0x25, 0x71,
      0xF3, 0x32, 0xA2, 0x36, 0x3A, 0x46, 0xFC, 0xE7, 0x02, 0x09, 0x51,
      0x71, 0x07, 0x02, 0xCD, 0xFB, 0xB6, 0xEE, 0xDA, 0x33, 0x05 },
    "MEExCzAJBgNVBAYTAlJPMRQwEgYDVQQKEwtDRVJUU0lHTiBTQTEcMBoGA1UECxMT"
    "Y2VydFNJR04gUk9PVCBDQSBHMg==",
    "EQA0tk7GNi02",
  },
  {
    // CN=IdenTrust Commercial Root CA 1,O=IdenTrust,C=US
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x5D, 0x56, 0x49, 0x9B, 0xE4, 0xD2, 0xE0, 0x8B, 0xCF, 0xCA, 0xD0,
      0x8A, 0x3E, 0x38, 0x72, 0x3D, 0x50, 0x50, 0x3B, 0xDE, 0x70, 0x69,
      0x48, 0xE4, 0x2F, 0x55, 0x60, 0x30, 0x19, 0xE5, 0x28, 0xAE },
    "MEoxCzAJBgNVBAYTAlVTMRIwEAYDVQQKEwlJZGVuVHJ1c3QxJzAlBgNVBAMTHklk"
    "ZW5UcnVzdCBDb21tZXJjaWFsIFJvb3QgQ0EgMQ==",
    "CgFCgAAAAUUjyES1AAAAAg==",
  },
  {
    // CN=Trustwave Global Certification Authority,O="Trustwave Holdings, Inc.",L=Chicago,ST=Illinois,C=US
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x97, 0x55, 0x20, 0x15, 0xF5, 0xDD, 0xFC, 0x3C, 0x87, 0x88, 0xC0, 0x06, 0x94, 0x45, 0x55, 0x40, 0x88, 0x94, 0x45, 0x00, 0x84, 0xF1, 0x00, 0x86, 0x70, 0x86, 0xBC, 0x1A, 0x2B, 0xB5, 0x8D, 0xC8 },
    "MIGIMQswCQYDVQQGEwJVUzERMA8GA1UECAwISWxsaW5vaXMxEDAOBgNVBAcMB0No"
    "aWNhZ28xITAfBgNVBAoMGFRydXN0d2F2ZSBIb2xkaW5ncywgSW5jLjExMC8GA1UE"
    "AwwoVHJ1c3R3YXZlIEdsb2JhbCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eQ==",
    "BfcOhtpJ80Y1Lrqy",
  },
  {
    // CN=Trustwave Global ECC P256 Certification Authority,O="Trustwave Holdings, Inc.",L=Chicago,ST=Illinois,C=US
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x94, 0x5B, 0xBC, 0x82, 0x5E, 0xA5, 0x54, 0xF4, 0x89, 0xD1, 0xFD, 0x51, 0xA7, 0x3D, 0xDF, 0x2E, 0xA6, 0x24, 0xAC, 0x70, 0x19, 0xA0, 0x52, 0x05, 0x22, 0x5C, 0x22, 0xA7, 0x8C, 0xCF, 0xA8, 0xB4 },
    "MIGRMQswCQYDVQQGEwJVUzERMA8GA1UECBMISWxsaW5vaXMxEDAOBgNVBAcTB0No"
    "aWNhZ28xITAfBgNVBAoTGFRydXN0d2F2ZSBIb2xkaW5ncywgSW5jLjE6MDgGA1UE"
    "AxMxVHJ1c3R3YXZlIEdsb2JhbCBFQ0MgUDI1NiBDZXJ0aWZpY2F0aW9uIEF1dGhv"
    "cml0eQ==",
    "DWpfCD8oXD5Rld9d",
  },
  {
    // CN=Trustwave Global ECC P384 Certification Authority,O="Trustwave Holdings, Inc.",L=Chicago,ST=Illinois,C=US
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x55, 0x90, 0x38, 0x59, 0xC8, 0xC0, 0xC3, 0xEB, 0xB8, 0x75, 0x9E, 0xCE, 0x4E, 0x25, 0x57, 0x22, 0x5F, 0xF5, 0x75, 0x8B, 0xBD, 0x38, 0xEB, 0xD4, 0x82, 0x76, 0x60, 0x1E, 0x1B, 0xD5, 0x80, 0x97 },
    "MIGRMQswCQYDVQQGEwJVUzERMA8GA1UECBMISWxsaW5vaXMxEDAOBgNVBAcTB0No"
    "aWNhZ28xITAfBgNVBAoTGFRydXN0d2F2ZSBIb2xkaW5ncywgSW5jLjE6MDgGA1UE"
    "AxMxVHJ1c3R3YXZlIEdsb2JhbCBFQ0MgUDM4NCBDZXJ0aWZpY2F0aW9uIEF1dGhv"
    "cml0eQ==",
    "CL2Fl2yZJ6SAaEc7",
  },
  {
    // CN=GlobalSign Root R46,O=GlobalSign nv-sa,C=BE
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x4F, 0xA3, 0x12, 0x6D, 0x8D, 0x3A, 0x11, 0xD1, 0xC4, 0x85, 0x5A, 0x4F, 0x80, 0x7C, 0xBA, 0xD6, 0xCF, 0x91, 0x9D, 0x3A, 0x5A, 0x88, 0xB0, 0x3B, 0xEA, 0x2C, 0x63, 0x72, 0xD9, 0x3C, 0x40, 0xC9 },
    "MEYxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMRwwGgYD"
    "VQQDExNHbG9iYWxTaWduIFJvb3QgUjQ2",
    "EdK7udcjGJ5AXwqdLdDfJWfR",
  },
  {
    // CN=GlobalSign Root E46,O=GlobalSign nv-sa,C=BE
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0xCB, 0xB9, 0xC4, 0x4D, 0x84, 0xB8, 0x04, 0x3E, 0x10, 0x50, 0xEA, 0x31, 0xA6, 0x9F, 0x51, 0x49, 0x55, 0xD7, 0xBF, 0xD2, 0xE2, 0xC6, 0xB4, 0x93, 0x01, 0x01, 0x9A, 0xD6, 0x1D, 0x9F, 0x50, 0x58 },
    "MEYxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMRwwGgYD"
    "VQQDExNHbG9iYWxTaWduIFJvb3QgRTQ2",
    "EdK7ujNu1LzmJGjFDYQdmOhD",
  },
  {
    // "CN=AC RAIZ FNMT-RCM SERVIDORES SEGUROS,OID.2.5.4.97=VATES-Q2826004J,OU=Ceres,O=FNMT-RCM,C=E
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x55, 0x41, 0x53, 0xB1, 0x3D, 0x2C, 0xF9, 0xDD, 0xB7, 0x53, 0xBF, 0xBE, 0x1A, 0x4E, 0x0A, 0xE0, 0x8D, 0x0A, 0xA4, 0x18, 0x70, 0x58, 0xFE, 0x60, 0xA2, 0xB8, 0x62, 0xB2, 0xE4, 0xB8, 0x7B, 0xCB },
    "MHgxCzAJBgNVBAYTAkVTMREwDwYDVQQKDAhGTk1ULVJDTTEOMAwGA1UECwwFQ2Vy"
    "ZXMxGDAWBgNVBGEMD1ZBVEVTLVEyODI2MDA0SjEsMCoGA1UEAwwjQUMgUkFJWiBG"
    "Tk1ULVJDTSBTRVJWSURPUkVTIFNFR1VST1M=",
    "YvYybOXE42hcG2LdnC6dlQ==",
  },
  {
    // CN=GLOBALTRUST 2020,O=e-commerce monitoring GmbH,C=AT
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x9A, 0x29, 0x6A, 0x51, 0x82, 0xD1, 0xD4, 0x51, 0xA2, 0xE3, 0x7F, 0x43, 0x9B, 0x74, 0xDA, 0xAF, 0xA2, 0x67, 0x52, 0x33, 0x29, 0xF9, 0x0F, 0x9A, 0x0D, 0x20, 0x07, 0xC3, 0x34, 0xE2, 0x3C, 0x9A },
    "ME0xCzAJBgNVBAYTAkFUMSMwIQYDVQQKExplLWNvbW1lcmNlIG1vbml0b3Jpbmcg"
    "R21iSDEZMBcGA1UEAxMQR0xPQkFMVFJVU1QgMjAyMA==",
    "Wku9WvtPilv6ZeU=",
  },
  {
    // CN=Certum Extended Validation ECC CA,OU=Certum Certification Authority,O=Asseco Data Systems S.A.,C=PL
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x6B, 0x32, 0x80, 0x85, 0x62, 0x53, 0x18, 0xAA, 0x50, 0xD1, 0x73, 0xC9, 0x8D, 0x8B, 0xDA, 0x09, 0xD5, 0x7E, 0x27, 0x41, 0x3D, 0x11, 0x4C, 0xF7, 0x87, 0xA0, 0xF5, 0xD0, 0x6C, 0x03, 0x0C, 0xF6 },
    "MHQxCzAJBgNVBAYTAlBMMSEwHwYDVQQKExhBc3NlY28gRGF0YSBTeXN0ZW1zIFMu"
    "QS4xJzAlBgNVBAsTHkNlcnR1bSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTEZMBcG"
    "A1UEAxMQQ2VydHVtIEVDLTM4NCBDQQ==",
    "eI8nXIESUiClBNAt3bpz9A==",
  },
  {
    // CN=Certum Extended Validation RSA CA,OU=Certum Certification Authority,O=Asseco Data Systems S.A.,C=PL
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0xFE, 0x76, 0x96, 0x57, 0x38, 0x55, 0x77, 0x3E, 0x37, 0xA9, 0x5E, 0x7A, 0xD4, 0xD9, 0xCC, 0x96, 0xC3, 0x01, 0x57, 0xC1, 0x5D, 0x31, 0x76, 0x5B, 0xA9, 0xB1, 0x57, 0x04, 0xE1, 0xAE, 0x78, 0xFD },
    "MHoxCzAJBgNVBAYTAlBMMSEwHwYDVQQKExhBc3NlY28gRGF0YSBTeXN0ZW1zIFMu"
    "QS4xJzAlBgNVBAsTHkNlcnR1bSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTEfMB0G"
    "A1UEAxMWQ2VydHVtIFRydXN0ZWQgUm9vdCBDQQ==",
    "Hr9ZULjJgDdMBvfrVU+17Q==",
  },
  {
    // CN=ANF Secure Server Root CA,OU=ANF CA Raiz,O=ANF Autoridad de Certificacion,C=ES,serialNumber=G63287510
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0xFB, 0x8F, 0xEC, 0x75, 0x91, 0x69, 0xB9, 0x10, 0x6B, 0x1E, 0x51, 0x16, 0x44, 0xC6, 0x18, 0xC5, 0x13, 0x04, 0x37, 0x3F, 0x6C, 0x06, 0x43, 0x08, 0x8D, 0x8B, 0xEF, 0xFD, 0x1B, 0x99, 0x75, 0x99 },
    "MIGEMRIwEAYDVQQFEwlHNjMyODc1MTAxCzAJBgNVBAYTAkVTMScwJQYDVQQKEx5B"
    "TkYgQXV0b3JpZGFkIGRlIENlcnRpZmljYWNpb24xFDASBgNVBAsTC0FORiBDQSBS"
    "YWl6MSIwIAYDVQQDExlBTkYgU2VjdXJlIFNlcnZlciBSb290IENB",
    "DdPjvGz5a7E=",
  },
  {
    // CN=Hellenic Academic and Research Institutions ECC RootCA 2015,O=Hellenic Academic and Research Institutions Cert. Authority,L=Athens,C=GR
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x44, 0xB5, 0x45, 0xAA, 0x8A, 0x25, 0xE6, 0x5A, 0x73, 0xCA, 0x15,
      0xDC, 0x27, 0xFC, 0x36, 0xD2, 0x4C, 0x1C, 0xB9, 0x95, 0x3A, 0x06,
      0x65, 0x39, 0xB1, 0x15, 0x82, 0xDC, 0x48, 0x7B, 0x48, 0x33 },
    "MIGqMQswCQYDVQQGEwJHUjEPMA0GA1UEBxMGQXRoZW5zMUQwQgYDVQQKEztIZWxs"
    "ZW5pYyBBY2FkZW1pYyBhbmQgUmVzZWFyY2ggSW5zdGl0dXRpb25zIENlcnQuIEF1"
    "dGhvcml0eTFEMEIGA1UEAxM7SGVsbGVuaWMgQWNhZGVtaWMgYW5kIFJlc2VhcmNo"
    "IEluc3RpdHV0aW9ucyBFQ0MgUm9vdENBIDIwMTU=",
    "AA==",
  },
  {
    // CN=Hellenic Academic and Research Institutions RootCA 2015,O=Hellenic Academic and Research Institutions Cert. Authority,L=Athens,C=GR
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0xA0, 0x40, 0x92, 0x9A, 0x02, 0xCE, 0x53, 0xB4, 0xAC, 0xF4, 0xF2,
      0xFF, 0xC6, 0x98, 0x1C, 0xE4, 0x49, 0x6F, 0x75, 0x5E, 0x6D, 0x45,
      0xFE, 0x0B, 0x2A, 0x69, 0x2B, 0xCD, 0x52, 0x52, 0x3F, 0x36 },
    "MIGmMQswCQYDVQQGEwJHUjEPMA0GA1UEBxMGQXRoZW5zMUQwQgYDVQQKEztIZWxs"
    "ZW5pYyBBY2FkZW1pYyBhbmQgUmVzZWFyY2ggSW5zdGl0dXRpb25zIENlcnQuIEF1"
    "dGhvcml0eTFAMD4GA1UEAxM3SGVsbGVuaWMgQWNhZGVtaWMgYW5kIFJlc2VhcmNo"
    "IEluc3RpdHV0aW9ucyBSb290Q0EgMjAxNQ==",
    "AA==",
  },
  {
    // CN=HARICA TLS RSA Root CA 2021,O=Hellenic Academic and Research Institutions CA,C=GR
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0xD9, 0x5D, 0x0E, 0x8E, 0xDA, 0x79, 0x52, 0x5B, 0xF9, 0xBE, 0xB1,
      0x1B, 0x14, 0xD2, 0x10, 0x0D, 0x32, 0x94, 0x98, 0x5F, 0x0C, 0x62,
      0xD9, 0xFA, 0xBD, 0x9C, 0xD9, 0x99, 0xEC, 0xCB, 0x7B, 0x1D },
    "MGwxCzAJBgNVBAYTAkdSMTcwNQYDVQQKDC5IZWxsZW5pYyBBY2FkZW1pYyBhbmQg"
    "UmVzZWFyY2ggSW5zdGl0dXRpb25zIENBMSQwIgYDVQQDDBtIQVJJQ0EgVExTIFJT"
    "QSBSb290IENBIDIwMjE=",
    "OcqTHO9D88aOk8f0ZIk4fg==",
  },
  {
    // CN=HARICA TLS ECC Root CA 2021,O=Hellenic Academic and Research Institutions CA,C=GR
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x3F, 0x99, 0xCC, 0x47, 0x4A, 0xCF, 0xCE, 0x4D, 0xFE, 0xD5, 0x87,
      0x94, 0x66, 0x5E, 0x47, 0x8D, 0x15, 0x47, 0x73, 0x9F, 0x2E, 0x78,
      0x0F, 0x1B, 0xB4, 0xCA, 0x9B, 0x13, 0x30, 0x97, 0xD4, 0x01 },
    "MGwxCzAJBgNVBAYTAkdSMTcwNQYDVQQKDC5IZWxsZW5pYyBBY2FkZW1pYyBhbmQg"
    "UmVzZWFyY2ggSW5zdGl0dXRpb25zIENBMSQwIgYDVQQDDBtIQVJJQ0EgVExTIEVD"
    "QyBSb290IENBIDIwMjE=",
    "Z3SdjXfYO2rbIvT/WeK/zg==",
  },
  {
    // CN=vTrus Root CA,O="iTrusChina Co.,Ltd.",C=CN
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x8A, 0x71, 0xDE, 0x65, 0x59, 0x33, 0x6F, 0x42, 0x6C, 0x26, 0xE5,
      0x38, 0x80, 0xD0, 0x0D, 0x88, 0xA1, 0x8D, 0xA4, 0xC6, 0xA9, 0x1F,
      0x0D, 0xCB, 0x61, 0x94, 0xE2, 0x06, 0xC5, 0xC9, 0x63, 0x87 },
    "MEMxCzAJBgNVBAYTAkNOMRwwGgYDVQQKExNpVHJ1c0NoaW5hIENvLixMdGQuMRYw"
    "FAYDVQQDEw12VHJ1cyBSb290IENB",
    "Q+NxE9izWRRdt86M/TX9b7wFjUU=",
  },
  {
    // CN=vTrus ECC Root CA,O="iTrusChina Co.,Ltd.",C=CN
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x30, 0xFB, 0xBA, 0x2C, 0x32, 0x23, 0x8E, 0x2A, 0x98, 0x54, 0x7A,
      0xF9, 0x79, 0x31, 0xE5, 0x50, 0x42, 0x8B, 0x9B, 0x3F, 0x1C, 0x8E,
      0xEB, 0x66, 0x33, 0xDC, 0xFA, 0x86, 0xC5, 0xB2, 0x7D, 0xD3 },
    "MEcxCzAJBgNVBAYTAkNOMRwwGgYDVQQKExNpVHJ1c0NoaW5hIENvLixMdGQuMRow"
    "GAYDVQQDExF2VHJ1cyBFQ0MgUm9vdCBDQQ==",
    "bmq8WapTvpg5Z6LSa6Q75m0c1to=",
  },
  {
    // CN=Autoridad de Certificacion Firmaprofesional CIF A62634068,C=ES
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x57, 0xDE, 0x05, 0x83, 0xEF, 0xD2, 0xB2, 0x6E, 0x03, 0x61, 0xDA,
      0x99, 0xDA, 0x9D, 0xF4, 0x64, 0x8D, 0xEF, 0x7E, 0xE8, 0x44, 0x1C,
      0x3B, 0x72, 0x8A, 0xFA, 0x9B, 0xCD, 0xE0, 0xF9, 0xB2, 0x6A },
    "MFExCzAJBgNVBAYTAkVTMUIwQAYDVQQDDDlBdXRvcmlkYWQgZGUgQ2VydGlmaWNh"
    "Y2lvbiBGaXJtYXByb2Zlc2lvbmFsIENJRiBBNjI2MzQwNjg=",
    "G3Dp0v+ubHE=",
  },
  {
    // CN=NetLock Arany (Class Gold) Főtanúsítvány,OU=Tanúsítványkiadók (Certification Services),O=NetLock Kft.,L=Budapest,C=HU
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x6C, 0x61, 0xDA, 0xC3, 0xA2, 0xDE, 0xF0, 0x31, 0x50, 0x6B, 0xE0,
      0x36, 0xD2, 0xA6, 0xFE, 0x40, 0x19, 0x94, 0xFB, 0xD1, 0x3D, 0xF9,
      0xC8, 0xD4, 0x66, 0x59, 0x92, 0x74, 0xC4, 0x46, 0xEC, 0x98 },
    "MIGnMQswCQYDVQQGEwJIVTERMA8GA1UEBwwIQnVkYXBlc3QxFTATBgNVBAoMDE5l"
    "dExvY2sgS2Z0LjE3MDUGA1UECwwuVGFuw7pzw610dsOhbnlraWFkw7NrIChDZXJ0"
    "aWZpY2F0aW9uIFNlcnZpY2VzKTE1MDMGA1UEAwwsTmV0TG9jayBBcmFueSAoQ2xh"
    "c3MgR29sZCkgRsWRdGFuw7pzw610dsOhbnk=",
    "SUEs5AAQ",
  },
  {
    // CN=D-TRUST EV Root CA 1 2020,O=D-Trust GmbH,C=DE
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x08, 0x17, 0x0D, 0x1A, 0xA3, 0x64, 0x53, 0x90, 0x1A, 0x2F, 0x95,
      0x92, 0x45, 0xE3, 0x47, 0xDB, 0x0C, 0x8D, 0x37, 0xAB, 0xAA, 0xBC,
      0x56, 0xB8, 0x1A, 0xA1, 0x00, 0xDC, 0x95, 0x89, 0x70, 0xDB },
    "MEgxCzAJBgNVBAYTAkRFMRUwEwYDVQQKEwxELVRydXN0IEdtYkgxIjAgBgNVBAMT"
    "GUQtVFJVU1QgRVYgUm9vdCBDQSAxIDIwMjA=",
    "XwJB13qHfEwDo6yWjfv/0A==",
  },
  {
    // CN=BJCA Global Root CA1,O=BEIJING CERTIFICATE AUTHORITY,C=CN
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0xF3, 0x89, 0x6F, 0x88, 0xFE, 0x7C, 0x0A, 0x88, 0x27, 0x66, 0xA7,
      0xFA, 0x6A, 0xD2, 0x74, 0x9F, 0xB5, 0x7A, 0x7F, 0x3E, 0x98, 0xFB,
      0x76, 0x9C, 0x1F, 0xA7, 0xB0, 0x9C, 0x2C, 0x44, 0xD5, 0xAE },
    "MFQxCzAJBgNVBAYTAkNOMSYwJAYDVQQKDB1CRUlKSU5HIENFUlRJRklDQVRFIEFV"
    "VEhPUklUWTEdMBsGA1UEAwwUQkpDQSBHbG9iYWwgUm9vdCBDQTE=",
    "VW9l47TZkGobCdFsPsBsIA==",
  },
  {
    // CN=BJCA Global Root CA2,O=BEIJING CERTIFICATE AUTHORITY,C=CN
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x57, 0x4D, 0xF6, 0x93, 0x1E, 0x27, 0x80, 0x39, 0x66, 0x7B, 0x72,
      0x0A, 0xFD, 0xC1, 0x60, 0x0F, 0xC2, 0x7E, 0xB6, 0x6D, 0xD3, 0x09,
      0x29, 0x79, 0xFB, 0x73, 0x85, 0x64, 0x87, 0x21, 0x28, 0x82 },
    "MFQxCzAJBgNVBAYTAkNOMSYwJAYDVQQKDB1CRUlKSU5HIENFUlRJRklDQVRFIEFV"
    "VEhPUklUWTEdMBsGA1UEAwwUQkpDQSBHbG9iYWwgUm9vdCBDQTI=",
    "LBcIfWQqwP6FGFkGz7RK6w==",
  },
  {
    // CN=Sectigo Public Server Authentication Root E46,O=Sectigo Limited,C=GB
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0xC9, 0x0F, 0x26, 0xF0, 0xFB, 0x1B, 0x40, 0x18, 0xB2, 0x22, 0x27,
      0x51, 0x9B, 0x5C, 0xA2, 0xB5, 0x3E, 0x2C, 0xA5, 0xB3, 0xBE, 0x5C,
      0xF1, 0x8E, 0xFE, 0x1B, 0xEF, 0x47, 0x38, 0x0C, 0x53, 0x83 },
    "MF8xCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxNjA0BgNV"
    "BAMTLVNlY3RpZ28gUHVibGljIFNlcnZlciBBdXRoZW50aWNhdGlvbiBSb290IEU0"
    "Ng==",
    "QvLM2htpN0RfFf51KBC49A==",
  },
  {
    // CN=Sectigo Public Server Authentication Root R46,O=Sectigo Limited,C=GB
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x7B, 0xB6, 0x47, 0xA6, 0x2A, 0xEE, 0xAC, 0x88, 0xBF, 0x25, 0x7A,
      0xA5, 0x22, 0xD0, 0x1F, 0xFE, 0xA3, 0x95, 0xE0, 0xAB, 0x45, 0xC7,
      0x3F, 0x93, 0xF6, 0x56, 0x54, 0xEC, 0x38, 0xF2, 0x5A, 0x06 },
    "MF8xCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxNjA0BgNV"
    "BAMTLVNlY3RpZ28gUHVibGljIFNlcnZlciBBdXRoZW50aWNhdGlvbiBSb290IFI0"
    "Ng==",
    "dY39i658BwD6qSWn4cetFA==",
  },
  {
    // CN=TrustAsia Global Root CA G3,O="TrustAsia Technologies, Inc.",C=CN
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0xE0, 0xD3, 0x22, 0x6A, 0xEB, 0x11, 0x63, 0xC2, 0xE4, 0x8F, 0xF9,
      0xBE, 0x3B, 0x50, 0xB4, 0xC6, 0x43, 0x1B, 0xE7, 0xBB, 0x1E, 0xAC,
      0xC5, 0xC3, 0x6B, 0x5D, 0x5E, 0xC5, 0x09, 0x03, 0x9A, 0x08 },
    "MFoxCzAJBgNVBAYTAkNOMSUwIwYDVQQKDBxUcnVzdEFzaWEgVGVjaG5vbG9naWVz"
    "LCBJbmMuMSQwIgYDVQQDDBtUcnVzdEFzaWEgR2xvYmFsIFJvb3QgQ0EgRzM=",
    "ZPYOZXdhaqs7tOqFhLuxibhxkw8=",
  },
  {
    // CN=TrustAsia Global Root CA G4,O="TrustAsia Technologies, Inc.",C=CN
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0xBE, 0x4B, 0x56, 0xCB, 0x50, 0x56, 0xC0, 0x13, 0x6A, 0x52, 0x6D,
      0xF4, 0x44, 0x50, 0x8D, 0xAA, 0x36, 0xA0, 0xB5, 0x4F, 0x42, 0xE4,
      0xAC, 0x38, 0xF7, 0x2A, 0xF4, 0x70, 0xE4, 0x79, 0x65, 0x4C },
    "MFoxCzAJBgNVBAYTAkNOMSUwIwYDVQQKDBxUcnVzdEFzaWEgVGVjaG5vbG9naWVz"
    "LCBJbmMuMSQwIgYDVQQDDBtUcnVzdEFzaWEgR2xvYmFsIFJvb3QgQ0EgRzQ=",
    "TyNkuI6XY57GU4HBdk7LKnQV1tc=",
  },
  {
    // CN=Telekom Security TLS ECC Root 2020,O=Deutsche Telekom Security GmbH,C=DE
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0x57, 0x8A, 0xF4, 0xDE, 0xD0, 0x85, 0x3F, 0x4E, 0x59, 0x98, 0xDB,
      0x4A, 0xEA, 0xF9, 0xCB, 0xEA, 0x8D, 0x94, 0x5F, 0x60, 0xB6, 0x20,
      0xA3, 0x8D, 0x1A, 0x3C, 0x13, 0xB2, 0xBC, 0x7B, 0xA8, 0xE1 },
    "MGMxCzAJBgNVBAYTAkRFMScwJQYDVQQKDB5EZXV0c2NoZSBUZWxla29tIFNlY3Vy"
    "aXR5IEdtYkgxKzApBgNVBAMMIlRlbGVrb20gU2VjdXJpdHkgVExTIEVDQyBSb290"
    "IDIwMjA=",
    "NjqWjMlcsljN0AFdxeVXAA==",
  },
  {
    // CN=Telekom Security TLS RSA Root 2023,O=Deutsche Telekom Security GmbH,C=DE
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0xEF, 0xC6, 0x5C, 0xAD, 0xBB, 0x59, 0xAD, 0xB6, 0xEF, 0xE8, 0x4D,
      0xA2, 0x23, 0x11, 0xB3, 0x56, 0x24, 0xB7, 0x1B, 0x3B, 0x1E, 0xA0,
      0xDA, 0x8B, 0x66, 0x55, 0x17, 0x4E, 0xC8, 0x97, 0x86, 0x46 },
    "MGMxCzAJBgNVBAYTAkRFMScwJQYDVQQKDB5EZXV0c2NoZSBUZWxla29tIFNlY3Vy"
    "aXR5IEdtYkgxKzApBgNVBAMMIlRlbGVrb20gU2VjdXJpdHkgVExTIFJTQSBSb290"
    "IDIwMjM=",
    "IZxULej27HF3+k7ow3BXlw==",
  },
  {
    // CN=FIRMAPROFESIONAL CA ROOT-A WEB,OID.2.5.4.97=VATES-A62634068,O=Firmaprofesional SA,C=ES
    "2.23.140.1.1",
    "CA/Browser Forum EV OID",
    { 0xBE, 0xF2, 0x56, 0xDA, 0xF2, 0x6E, 0x9C, 0x69, 0xBD, 0xEC, 0x16,
      0x02, 0x35, 0x97, 0x98, 0xF3, 0xCA, 0xF7, 0x18, 0x21, 0xA0, 0x3E,
      0x01, 0x82, 0x57, 0xC5, 0x3C, 0x65, 0x61, 0x7F, 0x3D, 0x4A },
    "MG4xCzAJBgNVBAYTAkVTMRwwGgYDVQQKDBNGaXJtYXByb2Zlc2lvbmFsIFNBMRgw"
    "FgYDVQRhDA9WQVRFUy1BNjI2MzQwNjgxJzAlBgNVBAMMHkZJUk1BUFJPRkVTSU9O"
    "QUwgQ0EgUk9PVC1BIFdFQg==",
    "MZch7a+JQn81QYehZ1ZMbQ==",
  },
};

// TenFourFox issue 512, backport from ESR60: treat all EV roots as
// SEC_OID_UNKNOWN by default.
#define TENFOURFOX_EV_ARRAY_LENGTH(x) (sizeof(x) / sizeof((x)[0]))
static SECOidTag sEVInfoOIDTags[TENFOURFOX_EV_ARRAY_LENGTH(myTrustedEVInfos)];
static CERTCertificate* sEVCERTs[TENFOURFOX_EV_ARRAY_LENGTH(myTrustedEVInfos)];
static_assert(SEC_OID_UNKNOWN == 0,
  "We depend on zero-initialized globals being interpreted as SEC_OID_UNKNOWN.");
static_assert(TENFOURFOX_EV_ARRAY_LENGTH(sEVInfoOIDTags) == TENFOURFOX_EV_ARRAY_LENGTH(myTrustedEVInfos),
  "These arrays are used in parallel and must have the same length.");
static_assert(TENFOURFOX_EV_ARRAY_LENGTH(sEVCERTs) == TENFOURFOX_EV_ARRAY_LENGTH(myTrustedEVInfos),
  "These arrays are used in parallel and must have the same length.");

static SECOidTag
register_oid(const SECItem* oid_item, const char* oid_name)
{
  if (!oid_item)
    return SEC_OID_UNKNOWN;

  SECOidData od;
  od.oid.len = oid_item->len;
  od.oid.data = oid_item->data;
  od.offset = SEC_OID_UNKNOWN;
  od.desc = oid_name;
  od.mechanism = CKM_INVALID_MECHANISM;
  od.supportedExtension = INVALID_CERT_EXTENSION;
  return SECOID_AddEntry(&od);
}

static bool
isEVPolicy(SECOidTag policyOIDTag)
{
  for (const SECOidTag& oidTag : sEVInfoOIDTags) {
    if (policyOIDTag == oidTag) {
      return true;
    }
  }

  return false;
}

namespace mozilla { namespace psm {

bool
CertIsAuthoritativeForEVPolicy(const CERTCertificate* cert,
                               const mozilla::pkix::CertPolicyId& policy)
{
  PR_ASSERT(cert);
  if (!cert) {
    return false;
  }

  for (size_t iEV = 0; iEV < PR_ARRAY_SIZE(myTrustedEVInfos); ++iEV) {
    if (sEVCERTs[iEV] && CERT_CompareCerts(cert, sEVCERTs[iEV])) {
      const SECOidData* oidData = SECOID_FindOIDByTag(sEVInfoOIDTags[iEV]);
      if (oidData && oidData->oid.len == policy.numBytes &&
          !memcmp(oidData->oid.data, policy.bytes, policy.numBytes)) {
        return true;
      }
    }
  }

  return false;
}

static PRStatus
IdentityInfoInit()
{
  for (size_t iEV = 0; iEV < PR_ARRAY_SIZE(myTrustedEVInfos); ++iEV) {
    nsMyTrustedEVInfo& entry = myTrustedEVInfos[iEV];

    SECStatus rv;
    CERTIssuerAndSN ias;

    rv = ATOB_ConvertAsciiToItem(&ias.derIssuer, const_cast<char*>(entry.issuer_base64));
    PR_ASSERT(rv == SECSuccess);
    if (rv != SECSuccess) {
      return PR_FAILURE;
    }
    rv = ATOB_ConvertAsciiToItem(&ias.serialNumber,
                                 const_cast<char*>(entry.serial_base64));
    PR_ASSERT(rv == SECSuccess);
    if (rv != SECSuccess) {
      SECITEM_FreeItem(&ias.derIssuer, false);
      return PR_FAILURE;
    }

    ias.serialNumber.type = siUnsignedInteger;

    sEVCERTs[iEV] = CERT_FindCertByIssuerAndSN(nullptr, &ias);

    SECITEM_FreeItem(&ias.derIssuer, false);
    SECITEM_FreeItem(&ias.serialNumber, false);

    // If an entry is missing in the NSS root database, it may be because the
    // root database is out of sync with what we expect (e.g. a different
    // version of system NSS is installed). We assert on debug builds, but
    // silently continue on release builds. In both cases, the root cert does
    // not get EV treatment.
    if (!sEVCERTs[iEV]) {
#ifdef DEBUG
      // The debug CA structs are at positions 0 to NUM_TEST_EV_ROOTS - 1, and
      // are NOT in the NSS root DB.
      if (iEV < NUM_TEST_EV_ROOTS) {
        continue;
      }
#endif
      PR_NOT_REACHED("Could not find EV root in NSS storage");
// If we're hitting this assert, we probably need to update the EV roots stored
// in this file (see "Paste new EV roots here").
fprintf(stderr, "Warning: TenFourFox could not find an EV root in NSS storage.\n");
      continue;
    }

    unsigned char certFingerprint[SHA256_LENGTH];
    rv = PK11_HashBuf(SEC_OID_SHA256, certFingerprint,
                      sEVCERTs[iEV]->derCert.data,
                      static_cast<int32_t>(sEVCERTs[iEV]->derCert.len));
    PR_ASSERT(rv == SECSuccess);
    if (rv == SECSuccess) {
      bool same = !memcmp(certFingerprint, entry.ev_root_sha256_fingerprint,
                          sizeof(certFingerprint));
      PR_ASSERT(same);
      if (same) {

        SECItem ev_oid_item;
        ev_oid_item.data = nullptr;
        ev_oid_item.len = 0;
        rv = SEC_StringToOID(nullptr, &ev_oid_item, entry.dotted_oid, 0);
        PR_ASSERT(rv == SECSuccess);
        if (rv == SECSuccess) {
          sEVInfoOIDTags[iEV] = register_oid(&ev_oid_item, entry.oid_name);
          if (sEVInfoOIDTags[iEV] == SEC_OID_UNKNOWN) {
            rv = SECFailure;
          }
          SECITEM_FreeItem(&ev_oid_item, false);
        }
      } else {
        PR_SetError(SEC_ERROR_BAD_DATA, 0);
        rv = SECFailure;
      }
    }

    if (rv != SECSuccess) {
      CERT_DestroyCertificate(sEVCERTs[iEV]);
      sEVCERTs[iEV] = nullptr;
      sEVInfoOIDTags[iEV] = SEC_OID_UNKNOWN;
      return PR_FAILURE;
    }
  }

  return PR_SUCCESS;
}

static PRCallOnceType sIdentityInfoCallOnce;

void
EnsureIdentityInfoLoaded()
{
  (void) PR_CallOnce(&sIdentityInfoCallOnce, IdentityInfoInit);
}

void
CleanupIdentityInfo()
{
  for (size_t iEV = 0; iEV < PR_ARRAY_SIZE(myTrustedEVInfos); ++iEV) {
    if (sEVCERTs[iEV]) {
      CERT_DestroyCertificate(sEVCERTs[iEV]);
      sEVCERTs[iEV] = nullptr;
    }
  }

  memset(&sIdentityInfoCallOnce, 0, sizeof(PRCallOnceType));
}

// Find the first policy OID that is known to be an EV policy OID.
SECStatus
GetFirstEVPolicy(CERTCertificate* cert,
                 /*out*/ mozilla::pkix::CertPolicyId& policy,
                 /*out*/ SECOidTag& policyOidTag)
{
  if (!cert) {
    PR_SetError(SEC_ERROR_INVALID_ARGS, 0);
    return SECFailure;
  }

  if (cert->extensions) {
    for (int i=0; cert->extensions[i]; i++) {
      const SECItem* oid = &cert->extensions[i]->id;

      SECOidTag oidTag = SECOID_FindOIDTag(oid);
      if (oidTag != SEC_OID_X509_CERTIFICATE_POLICIES)
        continue;

      SECItem* value = &cert->extensions[i]->value;

      CERTCertificatePolicies* policies;
      CERTPolicyInfo** policyInfos;

      policies = CERT_DecodeCertificatePoliciesExtension(value);
      if (!policies)
        continue;

      policyInfos = policies->policyInfos;

      bool found = false;
      while (*policyInfos) {
        const CERTPolicyInfo* policyInfo = *policyInfos++;

        SECOidTag oid_tag = policyInfo->oid;
        if (oid_tag != SEC_OID_UNKNOWN && isEVPolicy(oid_tag)) {
          const SECOidData* oidData = SECOID_FindOIDByTag(oid_tag);
          PR_ASSERT(oidData);
          PR_ASSERT(oidData->oid.data);
          PR_ASSERT(oidData->oid.len > 0);
          PR_ASSERT(oidData->oid.len <= mozilla::pkix::CertPolicyId::MAX_BYTES);
          if (oidData && oidData->oid.data && oidData->oid.len > 0 &&
              oidData->oid.len <= mozilla::pkix::CertPolicyId::MAX_BYTES) {
            policy.numBytes = static_cast<uint16_t>(oidData->oid.len);
            memcpy(policy.bytes, oidData->oid.data, policy.numBytes);
            policyOidTag = oid_tag;
            found = true;
          }
          break;
        }
      }
      CERT_DestroyCertificatePoliciesExtension(policies);
      if (found) {
        return SECSuccess;
      }
    }
  }

  PR_SetError(SEC_ERROR_POLICY_VALIDATION_FAILED, 0);
  return SECFailure;
}

} } // namespace mozilla::psm
