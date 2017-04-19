/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim:set ts=2 sw=2 sts=2 et cindent: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <Cocoa/Cocoa.h>
#include <CoreServices/CoreServices.h>
#include <crt_externs.h>
#include <stdlib.h>
#include <stdio.h>
// #include <spawn.h> // we don't have this in 10.4.
#include "readstrings.h"

#define MAC_OS_X_VERSION_10_6_HEX 0x00001060
#define MAC_OS_X_VERSION_10_5_HEX 0x00001050
#define MAC_OS_X_VERSION_10_4_HEX 0x00001040 // which is all that matters :)

typedef int cpu_type_t; // we don't have cpu_type* on 10.4.
#define CPU_TYPE_ANY            ((cpu_type_t) -1)
#define CPU_TYPE_POWERPC        ((cpu_type_t) 18)

// we need this! we're PPC!
#ifdef __ppc__
#include <sys/types.h>
#include <sys/sysctl.h>
#include <mach/machine.h>
#endif /* __ppc__ */

SInt32 OSXVersion()
{
  static SInt32 gOSXVersion = 0x0;
  if (gOSXVersion == 0x0) {
    OSErr err = ::Gestalt(gestaltSystemVersion, &gOSXVersion);
    if (err != noErr) {
      // This should probably be changed when our minimum version changes
      printf("Couldn't determine OS X version, assuming 10.5");
      gOSXVersion = MAC_OS_X_VERSION_10_5_HEX;
    }
  }
  return gOSXVersion;
}

bool OnSnowLeopardOrLater()
{
  return (OSXVersion() >= MAC_OS_X_VERSION_10_6_HEX);
}

// We prefer an architecture based on OS and then the fallback
// CPU_TYPE_ANY for a total of 2.
#define CPU_ATTR_COUNT 2

void LaunchChild(int argc, char **argv)
{
#if(1)
/* Use the old 3.6 code. -- Cameron */
  int i;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSTask *child = [[[NSTask alloc] init] autorelease];
  NSMutableArray *args = [[[NSMutableArray alloc] init] autorelease];

#ifdef __ppc__
  // It's possible that the app is a universal binary running under Rosetta
  // translation because the user forced it to.  Relaunching via NSTask would
  // launch the app natively, which the user apparently doesn't want.
  // In that case, try to preserve translation.

  // If the sysctl doesn't exist, it's because Rosetta doesn't exist,
  // so don't try to force translation.  In case of other errors, just assume
  // that the app is native.

  int isNative = 0;
  size_t sz = sizeof(isNative);

  if (sysctlbyname("sysctl.proc_native", &isNative, &sz, NULL, 0) == 0 &&
      !isNative) {
    // Running translated on ppc.
    cpu_type_t preferredCPU = CPU_TYPE_POWERPC;
    sysctlbyname("sysctl.proc_exec_affinity", NULL, NULL,
                 &preferredCPU, sizeof(preferredCPU));

    // Nothing can be done to handle failure, relaunch anyway.
  }
#endif /* __ppc__ */

  for (i = 1; i < argc; ++i)
    [args addObject: [NSString stringWithCString: argv[i]]];

  [child setLaunchPath: [NSString stringWithCString: argv[0]]];
  [child setArguments: args];
  [child launch];
  [pool release];
#else // the 4.0 code as of beta 7
  // We prefer CPU_TYPE_X86_64 on 10.6 and CPU_TYPE_X86 on 10.5,
  // if that isn't possible we let the OS pick the next best 
  // thing (CPU_TYPE_ANY).
  cpu_type_t cpu_types[CPU_ATTR_COUNT];
  if (OnSnowLeopardOrLater()) {
    cpu_types[0] = CPU_TYPE_X86_64;
  }
  else {
    cpu_types[0] = CPU_TYPE_X86;
  }
  cpu_types[1] = CPU_TYPE_ANY;

  // Initialize spawn attributes.
  posix_spawnattr_t spawnattr;
  if (posix_spawnattr_init(&spawnattr) != 0) {
    printf("Failed to init posix spawn attribute.");
    return;
  }

  // Set spawn attributes.
  size_t attr_count = 2;
  size_t attr_ocount = 0;
  if (posix_spawnattr_setbinpref_np(&spawnattr, attr_count, pref_cpu_types, &attr_ocount) != 0 ||
      attr_ocount != attr_count) {
    printf("Failed to set binary preference on posix spawn attribute.");
    posix_spawnattr_destroy(&spawnattr);
    return;
  }

  // "posix_spawnp" uses null termination for arguments rather than a count.
  // Note that we are not duplicating the argument strings themselves.
  char** argv_copy = (char**)malloc((argc + 1) * sizeof(char*));
  if (!argv_copy) {
    printf("Failed to allocate memory for arguments.");
    posix_spawnattr_destroy(&spawnattr);
    return;
  }
  for (int i = 0; i < argc; i++) {
    argv_copy[i] = argv[i];
  }
  argv_copy[argc] = NULL;

  // Pass along our environment.
  char** envp = NULL;
  char*** cocoaEnvironment = _NSGetEnviron();
  if (cocoaEnvironment) {
    envp = *cocoaEnvironment;
  }

  int result = posix_spawnp(NULL, argv_copy[0], NULL, &spawnattr, argv_copy, envp);

  free(argv_copy);
  posix_spawnattr_destroy(&spawnattr);

  if (result != 0) {
    printf("Process spawn failed with code %d!", result);
  }
#endif
}

void
LaunchMacPostProcess(const char* aAppBundle)
{
  // Launch helper to perform post processing for the update; this is the Mac
  // analogue of LaunchWinPostProcess (PostUpdateWin).
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  NSString* iniPath = [NSString stringWithUTF8String:aAppBundle];
  iniPath =
    [iniPath stringByAppendingPathComponent:@"Contents/Resources/updater.ini"];

  NSFileManager* fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:iniPath]) {
    // the file does not exist; there is nothing to run
    [pool release];
    return;
  }

  int readResult;
  char values[2][MAX_TEXT_LEN];
  readResult = ReadStrings([iniPath UTF8String],
                           "ExeRelPath\0ExeArg\0",
                           2,
                           values,
                           "PostUpdateMac");
  if (readResult) {
    [pool release];
    return;
  }

  NSString *exeRelPath = [NSString stringWithUTF8String:values[0]];
  NSString *exeArg = [NSString stringWithUTF8String:values[1]];
  if (!exeArg || !exeRelPath) {
    [pool release];
    return;
  }

  NSString* exeFullPath = [NSString stringWithUTF8String:aAppBundle];
  exeFullPath = [exeFullPath stringByAppendingPathComponent:exeRelPath];

  char optVals[1][MAX_TEXT_LEN];
  readResult = ReadStrings([iniPath UTF8String],
                           "ExeAsync\0",
                           1,
                           optVals,
                           "PostUpdateMac");

  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:exeFullPath];
  [task setArguments:[NSArray arrayWithObject:exeArg]];
  [task launch];
  if (!readResult) {
    NSString *exeAsync = [NSString stringWithUTF8String:optVals[0]];
    if ([exeAsync isEqualToString:@"false"]) {
      [task waitUntilExit];
    }
  }
  // ignore the return value of the task, there's nothing we can do with it
  [task release];

  [pool release];
}
