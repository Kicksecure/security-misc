#!/bin/sh

### Copyrigh (C) 2023 - 2023 Friedrich Doku <friedrichdoku@gmail.com>

ram_wipe_action() {
   local kernel_wiperam_exit
   ## getarg returns the last parameter only.
   ## if /proc/cmdline contains 'wiperam=skip wiperam=force' the last one wins.
   kernel_wiperam_exit=$(getarg wiperamexit)


   if [ "$kernel_wiperam_exit" = "no" ]; then
      info "INFO: Skip, because wiperamexit=no kernel parameter detected, OK."
      return 0
   else 
      if [ "$kernel_wiperam_exit" != "yes" ]; then
         info "INFO: Skip, becuase wiperamexit parameter is not used. "
         return 0
      fi
   fi

   info "INFO: wiperamexit=yes. Running second RAM wipe... "
   
   sdmem -l -l -v
}
ram_wipe_action

