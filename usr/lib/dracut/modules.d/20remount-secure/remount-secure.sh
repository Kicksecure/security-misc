#!/bin/sh

## Copyright (C) 2023 - 2023 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## This script is intended to remount specified mount points with more secure
## options based on kernel command line parameters.

remount_hook() {
   local remount_action
   remount_action=$(getarg remountsecure)

   if getargbool 1 remountnoexec; then
      if ! remount-secure --remountnoexec ; then
         warn "'remount-secure --remountnoexec' failed."
         return 1
      fi
      info "'remount-secure --remountnoexec' success."
      return 0
   fi

   if getargbool 1 remountsecure; then
      if ! remount-secure ; then
         warn "'remount-secure' failed."
      fi
      info "'remount-secure' success."
      return 0
   fi

   warn "Not using remount-secure."
   return 1
}

remount_hook
