#!/bin/sh

## Copyright (C) 2023 - 2023 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## Copyright (C) 2023 - 2023 Friedrich Doku <friedrichdoku@gmail.com>
## See the file COPYING for copying conditions.

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

DRACUT_QUIET=no

ram_wipe_check_needshutdown() {
   local kernel_wiperam_setting
   kernel_wiperam_setting=$(getarg wiperam)

   if [ "$kernel_wiperam_setting" = "skip" ]; then
      warn "wipe-ram-needshutdown.sh: Skip, because wiperam=skip kernel parameter detected, OK."
      return 0
   fi

   if [ "$kernel_wiperam_setting" = "force" ]; then
      warn "wipe-ram-needshutdown.sh: wiperam=force detected, OK."
   else
      detect_virt_output="$(systemd-detect-virt 2>&1)"
      detect_virt_exit_code="$?"
      warn "wipe-ram-needshutdown.sh: detect_virt_output: '$detect_virt_output'"
      warn "wipe-ram-needshutdown.sh: detect_virt_exit_code: '$detect_virt_exit_code'"
      if [ "$detect_virt_exit_code" = "0" ]; then
         warn "wipe-ram-needshutdown.sh: Skip, because running inside a VM detected and not using wiperam=force kernel parameter, OK."
         return 0
      fi
      warn "wipe-ram-needshutdown.sh: Bare metal (not running inside a VM) detected, OK."
   fi

   warn "wipe-ram-needshutdown.sh: Calling dracut function need_shutdown to drop back into initramfs at shutdown, OK."
   need_shutdown

   return 0
}

ram_wipe_check_needshutdown
