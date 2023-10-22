#!/bin/bash

## Copyright (C) 2023 - 2023 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

# called by dracut
check() {
    require_binaries str_replace || return 1
    require_binaries mount || return 1
    require_binaries remount-secure || return 1
    return 0
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    inst_multiple str_replace
    inst_multiple mount
    inst_multiple remount-secure
    inst_hook cleanup 90 "$moddir/remount-secure.sh"
}

# called by dracut
installkernel() {
    return 0
}
