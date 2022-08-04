#!/bin/sh

## Author: friedy10 friedrichdoku@gmail.com


ram_wipe_check_needshutdown() {
   local wipe_action
   wipe_action=$(getarg wiperamaction)

   if [ "$wipe_action" = "reboot" ]; then
      reboot -f
   fi

   if [ "$wipe_action" = "poweroff" ]; then
      poweroff -f
   fi
   
   if [ "$wipe_action" = "halt" ]; then
      echo "INFO: Halting..."
      halt -f
   fi
}

ram_wipe_check_needshutdown
