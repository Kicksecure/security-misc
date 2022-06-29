#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    require_binaries sleep || return 1
    require_binaries dmsetup || return 1
    require_binaries sdmem || return 1
    return 0
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    inst_multiple sleep
    inst_multiple sdmem
    inst_multiple dmsetup
    inst_hook shutdown 40 "$moddir/wipe.sh"
    inst_hook cleanup 80 "$moddir/wipe-needshutdown.sh"
}

# called by dracut
installkernel() {
    return 0
}
