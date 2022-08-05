#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

## Copyright (C) 2022 - 2022 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## Credits:
## First version by @friedy10.
## https://github.com/friedy10/dracut/blob/master/modules.d/40sdmem/module-setup.sh

# called by dracut
check() {
    require_binaries sync || return 1
    require_binaries sleep || return 1
    require_binaries kexec || return 1
    require_binaries cat || return 1
    require_binaries sdmem || return 1
    require_binaries dmsetup || return 1
    require_binaries ls || return 1
    require_binaries sort || return 1
    require_binaries tail || return 1
    require_binaries sed || return 1
    require_binaries grep || return 1
    require_binaries cut || return 1
    require_binaries fdisk || return 1
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
    inst_multiple kexec
    inst_multiple ls
    inst_multiple sort
    inst_multiple tail
    inst_multiple sed
    inst_multiple grep
    inst_multiple cut
    inst_multiple fdisk
    inst_multiple cat
    inst_multiple dmsetup
    inst_multiple systemd-detect-virt
    inst_hook shutdown 40 "$moddir/wipe-ram.sh"
    inst_hook cleanup 80 "$moddir/wipe-ram-needshutdown.sh"
}

# called by dracut
installkernel() {
    return 0
}
