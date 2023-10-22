#!/bin/sh

## Copyright (C) 2023 - 2023 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## This script is intended to remount specified mount points with more secure
## options based on kernel command line parameters.

remount_hook() {
   local remountsecure_action
   ## getarg returns the last parameter only.
   ## if /proc/cmdline contains 'remountsecure=0 remountsecure=1 remountsecure=noexec' the last one wins.
   remountsecure_action=$(getarg remountsecure)

   if [ "$remountsecure_action" = "1" ]; then
      if ! remount-secure; then
         warn "$0: ERROR: 'remount-secure' failed."
         return 1
      fi
      info "$0: INFO: 'remount-secure' success."
      return 0
   fi

   if [ "$remountsecure_action" = "noexec" ]; then
      if ! remount-secure --remountnoexec; then
         warn "$0: ERROR: 'remount-secure --remountnoexec' failed."
         return 1
      fi
      info "$0: INFO: 'remount-secure --remountnoexec' success."
      return 0
   fi

   warn "$0: WARNING: Not using remount-secure."
   return 1
}

remount_hook
