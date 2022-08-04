#!/bin/sh

## Author: friedy10 friedrichdoku@gmail.com

ram_wipe_action() {
   local kernel_wiperam_exit
   ## getarg returns the last parameter only.
   ## if /proc/cmdline contains 'wiperam=skip wiperam=force' the last one wins.
   kernel_wiperam_exit=$(getarg wiperamexit)


   if [ "$kernel_wiperam_exit" = "no" ]; then
      echo "INFO: Skip, because wiperamexit=no kernel parameter detected, OK."
      return 0
   else 
      if [ "$kernel_wiperam_exit" != "yes" ]; then
         echo "INFO: Skip, becuase wiperamexit parameter is not used. "
         return 0
      fi
   fi

   echo "INFO: wiperamexit=yes. Running second RAM wipe... "

   set -e
   sdmem -l -l
}
ram_wipe_action
