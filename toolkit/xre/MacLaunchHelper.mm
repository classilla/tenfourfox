/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "MacLaunchHelper.h"

#include "nsMemory.h"
#include "nsAutoPtr.h"
#include "nsIAppStartup.h"

#include <stdio.h>
// #include <spawn.h> // 10.4 doesn't have spawn. It's rated PG. No sex.
#include <crt_externs.h>

#include "nsObjCExceptions.h"
#include <Cocoa/Cocoa.h>
#ifdef __ppc__
#include <sys/types.h>
#include <sys/sysctl.h>
#include <mach/machine.h>
#endif /* __ppc__ */

using namespace mozilla;

#if(0) // We don't need to use this.
namespace {
cpu_type_t pref_cpu_types[2] = {
#if defined(__i386__)
                                 CPU_TYPE_X86,
#elif defined(__x86_64__)
                                 CPU_TYPE_X86_64,
#elif defined(__ppc__)
                                 CPU_TYPE_POWERPC,
#endif
                                 CPU_TYPE_ANY };

cpu_type_t cpu_i386_types[2] = {
                                 CPU_TYPE_X86,
                                 CPU_TYPE_ANY };

cpu_type_t cpu_x64_86_types[2] = {
                                 CPU_TYPE_X86_64,
                                 CPU_TYPE_ANY };
} // namespace
#endif

void LaunchChildMac(int aArgc, char** aArgv,
                    uint32_t aRestartType, pid_t *pid)
{
#if(1)
/* Use the 3.6 code for 10.4Fx, except that we now extract the pid for
   consumers, unless (!pid). -- Cameron */
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  int i;
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  NSTask* child = [[[NSTask alloc] init] autorelease];
  if (pid) *pid = (pid_t)[child processIdentifier]; // XXX?
  NSMutableArray* args = [[[NSMutableArray alloc] init] autorelease];

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

  for (i = 1; i < aArgc; ++i)
    [args addObject: [NSString stringWithCString: aArgv[i]]];

  [child setCurrentDirectoryPath:[[[NSBundle mainBundle] executablePath] stringByDeletingLastPathComponent]];
  [child setLaunchPath:[[NSBundle mainBundle] executablePath]];
  [child setArguments:args];
  [child launch];
  [pool release];

  NS_OBJC_END_TRY_ABORT_BLOCK;
#else
  // "posix_spawnp" uses null termination for arguments rather than a count.
  // Note that we are not duplicating the argument strings themselves.
  nsAutoArrayPtr<char*> argv_copy(new char*[aArgc + 1]);
  for (int i = 0; i < aArgc; i++) {
    argv_copy[i] = aArgv[i];
  }
  argv_copy[aArgc] = NULL;

  // Initialize spawn attributes.
  posix_spawnattr_t spawnattr;
  if (posix_spawnattr_init(&spawnattr) != 0) {
    printf("Failed to init posix spawn attribute.");
    return;
  }

  cpu_type_t *wanted_type = pref_cpu_types;
  size_t attr_count = ArrayLength(pref_cpu_types);

  if (aRestartType & nsIAppStartup::eRestarti386) {
    wanted_type = cpu_i386_types;
    attr_count = ArrayLength(cpu_i386_types);
  } else if (aRestartType & nsIAppStartup::eRestartx86_64) {
    wanted_type = cpu_x64_86_types;
    attr_count = ArrayLength(cpu_x64_86_types);
  }

  // Set spawn attributes.
  size_t attr_ocount = 0;
  if (posix_spawnattr_setbinpref_np(&spawnattr, attr_count, wanted_type, &attr_ocount) != 0 ||
      attr_ocount != attr_count) {
    printf("Failed to set binary preference on posix spawn attribute.");
    posix_spawnattr_destroy(&spawnattr);
    return;
  }

  // Pass along our environment.
  char** envp = NULL;
  char*** cocoaEnvironment = _NSGetEnviron();
  if (cocoaEnvironment) {
    envp = *cocoaEnvironment;
  }

  int result = posix_spawnp(pid, argv_copy[0], NULL, &spawnattr, argv_copy, envp);

  posix_spawnattr_destroy(&spawnattr);

  if (result != 0) {
    printf("Process spawn failed with code %d!", result);
  }
#endif
}
