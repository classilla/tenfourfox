#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import re
import subprocess
import sys

"""Prints the lowest locally available SDK version greater than or equal to a
given minimum sdk version to standard output.

Usage:
  python find_sdk.py 10.6  # Ignores SDKs < 10.6
"""

from optparse import OptionParser


def parse_version(version_str):
  """'10.6' => [10, 6]"""
  return map(int, re.findall(r'(\d+)', version_str))


def main():
  parser = OptionParser()
  parser.add_option("--verify",
                    action="store_true", dest="verify", default=False,
                    help="return the sdk argument and warn if it doesn't exist")
  parser.add_option("--sdk_path",
                    action="store", type="string", dest="sdk_path", default="",
                    help="user-specified SDK path; bypasses verification")
  (options, args) = parser.parse_args()
  min_sdk_version = args[0]

  if sys.platform == 'darwin':
    # short circuit this, since we only support 10.4 and 10.5
    # I HATE PYTHON INDENTS
    sdk_dir = '/Developer/SDKs';
    sdks = [re.findall('^MacOSX(10\..+)\.sdk$', s) for s in os.listdir(sdk_dir)]
    sdks = [s[0] for s in sdks if s]  # [['10.5'], ['10.6']] => ['10.5', '10.6']
    sdks = [s for s in sdks  # ['10.5', '10.6'] => ['10.6']
            if parse_version(s) >= parse_version(min_sdk_version)]
    if not sdks:
      raise Exception('No %s+ SDK found' % min_sdk_version)
    best_sdk = sorted(sdks, key=parse_version)[0]
  else:
    best_sdk = ""

  if options.verify and best_sdk != min_sdk_version and not options.sdk_path:
    print >>sys.stderr, ''
    print >>sys.stderr, '                                           vvvvvvv'
    print >>sys.stderr, ''
    print >>sys.stderr, \
        'This build requires the %s SDK, but it was not found on your system.' \
        % min_sdk_version
    print >>sys.stderr, \
        'Either install it, or explicitly set mac_sdk in your GYP_DEFINES.'
    print >>sys.stderr, ''
    print >>sys.stderr, '                                           ^^^^^^^'
    print >>sys.stderr, ''
    return min_sdk_version

  return best_sdk


if __name__ == '__main__':
  print main()
