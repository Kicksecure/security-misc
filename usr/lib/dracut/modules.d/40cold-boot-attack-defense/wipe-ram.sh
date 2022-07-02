#!/bin/sh

## Copyright (C) 2022 - 2022 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## Credits:
## First version by @friedy10.
## https://github.com/friedy10/dracut/blob/master/modules.d/40sdmem/wipe.sh

ram_wipe() {
   local kernel_wiperam_setting
   ## getarg returns the last parameter only.
   ## if /proc/cmdline contains 'wiperam=skip wiperam=force' the last one wins.
   kernel_wiperam_setting=$(getarg wiperam)

   if [ "$kernel_wiperam_setting" = "skip" ]; then
      echo "INFO: wipe-ram.sh: Skip, because wiperam=skip kernel parameter detected, OK." > /dev/kmsg
      return 0
   fi

   if [ "$kernel_wiperam_setting" = "force" ]; then
      echo "INFO: wipe-ram.sh: wiperam=force detected, OK." > /dev/kmsg
   else
      if systemd-detect-virt &>/dev/null ; then
         echo "INFO: wipe-ram.sh: Skip, because VM detected and not using wiperam=force kernel parameter, OK." > /dev/kmsg
         return 0
      fi
   fi

   echo "INFO: wipe-ram.sh: Cold boot attack defense... Starting RAM wipe on shutdown..." > /dev/kmsg

   ## https://gitlab.tails.boum.org/tails/tails/-/blob/master/config/chroot_local-includes/usr/local/lib/initramfs-pre-shutdown-hook
   ### Ensure any remaining disk cache is erased by Linux' memory poisoning
   echo 3 > /proc/sys/vm/drop_caches

   ## TODO: sdmem settings. One pass only. Secure? Configurable?
   ## TODO: > /dev/kmsg 2> /dev/kmsg
   sdmem -l -l -v

   echo "INFO: wipe-ram.sh: RAM wipe completed, OK." > /dev/kmsg

   ## In theory might be better to check this beforehand, but the test is
   ## really fast. The user has no chance of reading the console output
   ## without introducing an artificial delay because the sdmem which runs
   ## after this, results in much more console output.
   echo "INFO: wipe-ram.sh: Checking if there are still mounted encrypted disks..." > /dev/kmsg

   local dmsetup_actual_output dmsetup_expected_output
   dmsetup_actual_output="$(dmsetup ls --target crypt)"
   dmsetup_expected_output="No devices found"

   if [ "$dmsetup_actual_output" = "$dmsetup_expected_output" ]; then
      echo "INFO: wipe-ram.sh: Success, there are no more mounted encrypted disks, OK." > /dev/kmsg
   else
      echo "\
WARNING: wipe-ram.sh:There are still mounted encrypted disks! RAM wipe failed!

debugging information:
dmsetup_expected_output: '$dmsetup_expected_output'
dmsetup_actual_output: '$dmsetup_actual_output'" > /dev/kmsg
   fi

   sleep 3
}

ram_wipe
