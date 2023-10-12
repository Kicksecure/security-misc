#!/bin/sh

## Copyright (C) 2019 - 2023 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

if [ -z "$XDG_CONFIG_DIRS" ]; then
   XDG_CONFIG_DIRS=/etc/xdg
fi
export XDG_CONFIG_DIRS=/usr/share/security-misc/:$XDG_CONFIG_DIRS

if [ -x /usr/libexec/security-misc/panic-on-oops ]; then
   sudo --non-interactive /usr/libexec/security-misc/panic-on-oops
fi
