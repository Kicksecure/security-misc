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
   fi

   if [ "$wipe_action" = "poweroff" ]; then
      info "wipe-ram.sh wiperamexit: poweroff..."
      poweroff --force
   fi

   if [ "$wipe_action" = "halt" ]; then
      info "wipe-ram.sh wiperamexit: halt..."
      halt --force
   fi

   if [ "$wipe_action" = "error" ]; then
      info "wipe-ram.sh wiperamexit: Choice of shutdown option led to an error. Shutting down..."
      sleep 5
      poweroff --force
   fi
}

ram_wipe_check_needshutdown
