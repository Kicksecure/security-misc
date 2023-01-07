#!/bin/sh

## Copyright (C) 2023 - 2023 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## Copyright (C) 2023 - 2023 Friedrich Doku <friedrichdoku@gmail.com>
## See the file COPYING for copying conditions.


ram_wipe_check_needshutdown() {
   local wipe_action
   wipe_action=$(getarg wiperamaction)

   wait $(pgrep sdmem)
   info "DONE WAITING..."

   if [ "$wipe_action" = "reboot" ]; then
      reboot -f
   fi

   if [ "$wipe_action" = "poweroff" ]; then
      poweroff -f
   fi

   if [ "$wipe_action" = "halt" ]; then
      halt -f
   fi

   if [ "$wipe_action" = "error" ]; then
      info "Choice of shutdown option led to an error. Shutting down..."
      sleep 5
      poweroff -f
   fi
}

ram_wipe_check_needshutdown
