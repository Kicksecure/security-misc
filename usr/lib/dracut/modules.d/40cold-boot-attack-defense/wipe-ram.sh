#!/bin/sh

## Copyright (C) 2023 - 2023 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## Copyright (C) 2023 - 2023 Friedrich Doku <friedrichdoku@gmail.com>
## See the file COPYING for copying conditions.

## Credits:
## First version by @friedy10.
## https://github.com/friedy10/dracut/blob/master/modules.d/40sdmem/wipe.sh

DRACUT_QUIET=no

drop_caches() {
   sync
   ## https://gitlab.tails.boum.org/tails/tails/-/blob/master/config/chroot_local-includes/usr/local/lib/initramfs-pre-shutdown-hook
   ### Ensure any remaining disk cache is erased by Linux' memory poisoning
   echo 3 > /proc/sys/vm/drop_caches
   sync
}

ram_wipe() {
   local kernel_wiperam_setting
   ## getarg returns the last parameter only.
   ## if /proc/cmdline contains 'wiperam=skip wiperam=force' the last one wins.
   kernel_wiperam_setting=$(getarg wiperam)

   if [ "$kernel_wiperam_setting" = "skip" ]; then
      warn "wipe-ram.sh: Skip, because wiperam=skip kernel parameter detected, OK."
      return 0
   fi

   if [ "$kernel_wiperam_setting" = "force" ]; then
      warn "wipe-ram.sh: wiperam=force detected, OK."
   else
      if systemd-detect-virt &>/dev/null ; then
         warn "wipe-ram.sh: Skip, because VM detected and not using wiperam=force kernel parameter, OK."
         return 0
      fi
   fi

   kernel_wiperamexit_setting=$(getarg wiperamexit)
   if [ "$kernel_wiperamexit_setting" = "yes" ]; then
      warn "wipe-ram.sh: Skip, because wiperamexit=yes to avoid RAM wipe reboot loop."
      return 0
   fi

   warn "wipe-ram.sh: Cold boot attack defense... Starting RAM wipe on shutdown..."

   drop_caches

   ## TODO: sdmem settings. One pass only. Secure? Configurable?
   ## TODO: > /dev/kmsg 2> /dev/kmsg
   sdmem -l -l -v

   drop_caches

   warn "wipe-ram.sh: RAM wipe completed, OK."

   ## In theory might be better to check this beforehand, but the test is
   ## really fast. The user has no chance of reading the console output
   ## without introducing an artificial delay because the sdmem which runs
   ## after this, results in much more console output.
   warn "wipe-ram.sh: Checking if there are still mounted encrypted disks..."

   local dmsetup_actual_output dmsetup_expected_output
   dmsetup_actual_output="$(dmsetup ls --target crypt)"
   dmsetup_expected_output="No devices found"

   if [ "$dmsetup_actual_output" = "$dmsetup_expected_output" ]; then
      warn "wipe-ram.sh: Success, there are no more mounted encrypted disks, OK."
   else
      ## dracut should unmount the root encrypted disk cryptsetup luksClose during shutdown
      ## https://github.com/dracutdevs/dracut/issues/1888
      warn "\
wipe-ram.sh: There are still mounted encrypted disks! RAM wipe incomplete!

debugging information:
dmsetup_expected_output: '$dmsetup_expected_output'
dmsetup_actual_output: '$dmsetup_actual_output'"
      ## How else could the user be informed that something is wrong?
      sleep 5
   fi

   warn "wipe-ram.sh: Now running 'kexec --exec'..."
   if kexec --exec ; then
      warn "wipe-ram.sh: 'kexec --exec' succeeded."
      return 0
   fi

   warn "wipe-ram.sh: 'kexec --exec' failed!"
   sleep 5
}

ram_wipe
