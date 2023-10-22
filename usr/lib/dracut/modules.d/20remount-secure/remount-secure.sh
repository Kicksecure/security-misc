#!/bin/sh

## Copyright (C) 2023 - 2023 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

remount_hook() {
   local remount_action
   remount_action=$(getarg remountsecure)

   if [ ! "$remount_action" = "yes" ]; then
      return 0
   fi

   remount-secure
}

remount_hook
