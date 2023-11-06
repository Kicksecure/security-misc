#!/bin/sh

## Copyright (C) 2023 - 2023 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## This script is intended to remount specified mount points with more secure
## options based on kernel command line parameters.

remount_hook() {
   local remountsecure_action
   ## getarg returns the last parameter only.
   ## If /proc/cmdline contains 'remountsecure=0 remountsecure=1' the last one wins.
   remountsecure_action=$(getarg remountsecure)

   if ! remount-secure $remountsecure_action; then
      warn "$0: ERROR: 'remount-secure $remountsecure_action' failed."
      return 1
   fi
   info "$0: INFO: 'remount-secure $remountsecure_action' success."
   return 0
}

remount_hook
