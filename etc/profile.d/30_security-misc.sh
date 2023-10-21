#!/bin/sh

## Copyright (C) 2019 - 2023 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

if [ -z "$XDG_CONFIG_DIRS" ]; then
   XDG_CONFIG_DIRS=/etc/xdg
fi
if ! echo "$XDG_CONFIG_DIRS" | grep --quiet /usr/share/security-misc/ ; then
   export XDG_CONFIG_DIRS=/usr/share/security-misc/:$XDG_CONFIG_DIRS
fi

if [ -x /usr/libexec/security-misc/panic-on-oops ]; then
   ## Hide output. Otherwise could confuse Qubes UpdatesProxy.
   sudo --non-interactive /usr/libexec/security-misc/panic-on-oops 1>/dev/null 2>/dev/null
fi
