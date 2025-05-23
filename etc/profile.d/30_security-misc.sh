#!/bin/sh

## Copyright (C) 2019 - 2025 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

if [ -z "$XDG_CONFIG_DIRS" ]; then
   XDG_CONFIG_DIRS="/etc/xdg"
fi
if ! printf '%s\n' "$XDG_CONFIG_DIRS" | grep -- "/usr/share/security-misc/" >/dev/null 2>/dev/null ; then
   export XDG_CONFIG_DIRS="/usr/share/security-misc/:$XDG_CONFIG_DIRS"
fi
