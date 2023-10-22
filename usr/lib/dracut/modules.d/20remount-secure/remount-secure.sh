#!/bin/sh

## Copyright (C) 2023 - 2023 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## This script is intended to remount specified mount points with more secure
## options based on kernel command line parameters.

remount_hook() {
   local remount_action
   remount_action=$(getarg remountsecure)

   if getargbool 1 remountnoexec; then
      remount-secure --remountnoexec
      return 0
   fi

   if getargbool 1 remountsecure; then
      remount-secure
      return 0
   fi
}

remount_hook
