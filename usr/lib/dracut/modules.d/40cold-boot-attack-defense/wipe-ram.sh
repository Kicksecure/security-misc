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

   info "wipe-ram.sh: START: COLD BOOT ATTACK DEFENSE - RAM WIPE ON SHUTDOWN"
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
      sleep 5
      return 0
   fi

   info "wipe-ram.sh: Starting RAM wipe..."

   ## - If DRACUT_QUIET previously was set to '', reset to '' for auto detection by check_quiet.
   ## - If DRACUT_QUIET previously was set to 'no', reset to 'no' for verbose output.
   ## - If DRACUT_QUIET previously was set to 'yes', reset to 'yes' to hide sdmem output,
   ##   as well as the oom killing at the end.
   DRACUT_QUIET="$OLD_DRACUT_QUIET"

   ## TODO: sdmem settings. One pass only. Secure? Configurable?
   sdmem -l -l -v

   ## Reset to DRACUT_QUIET='no' so info messages can be shown.
   DRACUT_QUIET='no'

   info "wipe-ram.sh: RAM wipe completed, OK."
   info "wipe-ram.sh: END: COLD BOOT ATTACK DEFENSE - RAM WIPE ON SHUTDOWN"

   ## Restore to previous value.
   DRACUT_QUIET="$OLD_DRACUT_QUIET"
   sleep 3
}

ram_wipe
