#!/bin/sh

ram_wipe() {
   info "$0: START: COLD BOOT ATTACK DEFENSE - RAM WIPE ON SHUTDOWN"

   info "$0: Checking if there are still mounted encrypted disks..."

   local dmsetup_actual_output dmsetup_expected_output
   dmsetup_actual_output="$(dmsetup ls --target crypt)"
   dmsetup_expected_output="No devices found"

   if [ "$dmsetup_actual_output" = "$dmsetup_expected_output" ]; then
      info "$0: Success, there are no more mounted encrypted disks, OK."
   else
      warn "\
$0: There are still mounted encrypted disks! RAM wipe failed!

debugging information:
dmsetup_expected_output: '$dmsetup_expected_output'
dmsetup_actual_output: '$dmsetup_actual_output'"
      return 0
   fi

   info "$0: Starting RAM wipe..."

   ## TODO: sdmem settings. One pass only. Secure? Configurable?
   sdmem -l -l -f

   info "$0: RAM wipe completed, OK."
   info "$0: END COLD BOOT ATTACK DEFENSE - RAM WIPE ON SHUTDOWN"
}

ram_wipe
