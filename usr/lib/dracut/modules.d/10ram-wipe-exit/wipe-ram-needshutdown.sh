#!/bin/sh

## Copyright (C) 2023 - 2023 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## Copyright (C) 2023 - 2023 Friedrich Doku <friedrichdoku@gmail.com>
## See the file COPYING for copying conditions.

ram_wipe_check_needshutdown() {
   local wipe_action
   wipe_action=$(getarg wiperamaction)

   ## TODO: disable
   wait $(pgrep sdmem)
   info "wipe-ram.sh wiperamexit: DONE WAITING..."

   if [ "$wipe_action" = "reboot" ]; then
      info "wipe-ram.sh wiperamexit: reboot..."
      reboot --force
   elif [ "$wipe_action" = "poweroff" ]; then
      info "wipe-ram.sh wiperamexit: poweroff..."
      poweroff --force
   elif [ "$wipe_action" = "halt" ]; then
      info "wipe-ram.sh wiperamexit: halt..."
      halt --force
   else
      info "wipe-ram.sh wiperamexit: normal boot..."
   fi
}

ram_wipe_check_needshutdown
