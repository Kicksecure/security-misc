#!/bin/sh

## Copyright (C) 2022 - 2022 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

ram_wipe_check_needshutdown() {
   local OLD_DRACUT_QUIET
   OLD_DRACUT_QUIET="$DRACUT_QUIET"
   DRACUT_QUIET='no'

   local kernel_wiperam_setting
   kernel_wiperam_setting=$(getarg wiperam)

   if [ "$kernel_wiperam_setting" = "skip" ]; then
      info "wipe-ram-needshutdown.sh: Skip, because wiperam=skip kernel parameter detected, OK."
      DRACUT_QUIET="$OLD_DRACUT_QUIET"
      return 0
   fi

   if [ "$kernel_wiperam_setting" = "force" ]; then
      info "wipe-ram-needshutdown.sh: wiperam=force detected, OK."
   else
      if systemd-detect-virt &>/dev/null ; then
         info "wipe-ram-needshutdown.sh: Skip, because running inside a VM detected and not using wiperam=force kernel parameter, OK."
         DRACUT_QUIET="$OLD_DRACUT_QUIET"
         return 0
      fi
      info "wipe-ram-needshutdown.sh: Bare metal (not running inside a VM) detected, OK."
   fi

   info "wipe-ram-needshutdown.sh: Calling dracut function need_shutdown to drop back into initramfs at shutdown, OK."
   need_shutdown

   DRACUT_QUIET="$OLD_DRACUT_QUIET"
   return 0
}

ram_wipe_check_needshutdown
