#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

## Copyright (C) 2023 - 2023 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## Copyright (C) 2023 - 2023 Friedrich Doku <friedrichdoku@gmail.com>
## See the file COPYING for copying conditions.

# called by dracut
check() {
   require_binaries sync || return 1
   require_binaries sleep || return 1
   require_binaries sdmem || return 1
   require_binaries dmsetup || return 1
   require_binaries systemd-detect-virt || return 1
   return 0
}

# called by dracut
depends() {
   return 0
}

# called by dracut
install() {
   inst_multiple sync
   inst_multiple sleep
   inst_multiple sdmem
   inst_multiple dmsetup
   inst_multiple systemd-detect-virt
   inst_hook shutdown 40 "$moddir/wipe-ram.sh"
   inst_hook cleanup 80 "$moddir/wipe-ram-needshutdown.sh"
}

# called by dracut
installkernel() {
   return 0
}
