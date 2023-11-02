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

# Set the default umask 0077. Whatever the access value the umask value is subtracted from it. Subtracting 7 means stripping
# all capabilities. This means that new files and folders created by a user will have no permission for group and others. 
umask 0077

## Once again disable core dumps by limiting the coredump file size to 0.
## One of the many places we disable coredumps in this package.
ulimit -c 0
