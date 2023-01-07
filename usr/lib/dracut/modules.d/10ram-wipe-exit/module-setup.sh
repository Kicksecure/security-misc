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
    require_binaries ls || return 1
    require_binaries halt || return 1
    require_binaries poweroff || return 1
    require_binaries reboot || return 1
    require_binaries cat || return 1
    require_binaries sdmem || return 1
    require_binaries pgrep || return 1
    require_binaries dmsetup || return 1
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
    inst_multiple ls
    inst_multiple halt
    inst_multiple poweroff
    inst_multiple reboot
    inst_multiple cat
    inst_multiple sdmem
    inst_multiple pgrep
    inst_multiple dmsetup
    inst_hook pre-udev 40 "$moddir/wipe-ram.sh"
    inst_hook pre-trigger 40 "$moddir/wipe-ram-needshutdown.sh"
}

# called by dracut
installkernel() {
    return 0
}
