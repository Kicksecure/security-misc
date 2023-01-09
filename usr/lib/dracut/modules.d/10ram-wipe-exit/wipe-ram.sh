#!/bin/sh

## Copyright (C) 2023 - 2023 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## Copyright (C) 2023 - 2023 Friedrich Doku <friedrichdoku@gmail.com>
## See the file COPYING for copying conditions.

## TODO: rename to wipe-ram-exit.sh (so it is different from wipe-ram.sh)

DRACUT_QUIET=no

drop_caches() {
   sync
   ## https://gitlab.tails.boum.org/tails/tails/-/blob/master/config/chroot_local-includes/usr/local/lib/initramfs-pre-shutdown-hook
   ### Ensure any remaining disk cache is erased by Linux' memory poisoning
   echo 3 > /proc/sys/vm/drop_caches
   sync
}

ram_wipe_action() {
   local kernel_wiperam_exit
   kernel_wiperam_exit=$(getarg wiperamexit)

   if [ "$kernel_wiperam_exit" = "no" ]; then
      warn "wipe-ram.sh wiperamexit: Skip, because wiperamexit=no kernel parameter detected, OK."
      return 0
   fi

   if [ "$kernel_wiperam_exit" != "yes" ]; then
      warn "wipe-ram.sh wiperamexit: Skip, because wiperamexit parameter is unset."
      return 0
   fi

   warn "wipe-ram.sh wiperamexit: wiperamexit=yes, therefore running second RAM wipe..."

   drop_caches
   sdmem -l -l -v
   drop_caches

   warn "wipe-ram.sh wiperamexit: Second RAM wipe completed."
}

ram_wipe_action
