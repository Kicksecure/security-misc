#!/bin/sh

## Copyrigh (C) 2023 - 2023 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## Copyrigh (C) 2023 - 2023 Friedrich Doku <friedrichdoku@gmail.com>
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
      detect_virt_output="$(systemd-detect-virt 2>&1)"
      detect_virt_exit_code="$?"
      info "wipe-ram-needshutdown.sh: detect_virt_output: '$detect_virt_output'"
      info "wipe-ram-needshutdown.sh: detect_virt_exit_code: '$detect_virt_exit_code'"
      if [ "$detect_virt_exit_code" = "0" ]; then
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
