#!/bin/sh

## Copyright (C) 2023 - 2023 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## Copyright (C) 2023 - 2023 Friedrich Doku <friedrichdoku@gmail.com>
## See the file COPYING for copying conditions.

DRACUT_QUIET=no

ram_wipe_check_needshutdown() {
   local wipe_action
   wipe_action=$(getarg wiperamaction)

   if [ "$wipe_action" = "reboot" ]; then
      warn "wipe-ram.sh wiperamexit: reboot..."
      ## Why reboot? Why not just continue to boot?
      ## To get rid of kernel command line options 'wiperamexit=yes wiperamaction=reboot'?
      ## Also RAM wipe using sdmem leads to an OOM and the following error as seen in serial console:
      ## [FAILED] Failed to start dracut pre-udev hook.
      ## In other words, the system might not boot up cleanly.
      reboot --force
   elif [ "$wipe_action" = "poweroff" ]; then
      warn "wipe-ram.sh wiperamexit: poweroff..."
      poweroff --force
   elif [ "$wipe_action" = "halt" ]; then
      warn "wipe-ram.sh wiperamexit: halt..."
      halt --force
   else
      warn "wipe-ram.sh wiperamexit: normal boot..."
   fi
}

ram_wipe_check_needshutdown
