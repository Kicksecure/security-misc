#!/bin/sh

## Copyright (C) 2022 - 2022 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## Credits:
## First version by @friedy10.
## https://github.com/friedy10/dracut/blob/master/modules.d/40sdmem/wipe.sh

ram_wipe() {
   local OLD_DRACUT_QUIET
   OLD_DRACUT_QUIET="$DRACUT_QUIET"
   ## check_quiet should show info in console.
   DRACUT_QUIET='no'

   if systemd-detect-virt &>/dev/null ; then
      info "wipe-ram.sh: Skip, because VM detected, OK."
      return 0
   fi

   info "wipe-ram.sh: Cold boot attack defense... Starting RAM wipe on shutdown..."

   ## TODO: sdmem settings. One pass only. Secure? Configurable?
   sdmem -l -l -v

   info "wipe-ram.sh: RAM wipe completed, OK."

   ## In theory might be better to check this beforehand, but the test is
   ## really fast. The user has no chance of reading the console output
   ## without introducing an artificial delay because the sdmem which runs
   ## after this, results in much more console output.
   info "wipe-ram.sh: Checking if there are still mounted encrypted disks..."

   local dmsetup_actual_output dmsetup_expected_output
   dmsetup_actual_output="$(dmsetup ls --target crypt)"
   dmsetup_expected_output="No devices found"

   if [ "$dmsetup_actual_output" = "$dmsetup_expected_output" ]; then
      info "wipe-ram.sh: Success, there are no more mounted encrypted disks, OK."
   else
      warn "\
wipe-ram.sh: There are still mounted encrypted disks! RAM wipe failed!

debugging information:
dmsetup_expected_output: '$dmsetup_expected_output'
dmsetup_actual_output: '$dmsetup_actual_output'"
   fi

   ## Restore to previous value.
   DRACUT_QUIET="$OLD_DRACUT_QUIET"
   sleep 3
}

ram_wipe
