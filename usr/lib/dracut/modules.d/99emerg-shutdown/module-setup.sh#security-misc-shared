#!/bin/bash

## Copyright (C) 2025 - 2025 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## called by dracut
check() {
  require_binaries /run/emerg-shutdown || return 1
  return 255
}

## called by dracut
depends() {
  echo 'systemd bash'
  return 0
}

## called by dracut
install() {
  local config_file

  inst systemd-notify

  inst_simple /usr/libexec/security-misc/emerg-shutdown
  inst_simple /usr/share/security-misc/emerg-shutdown-initramfs.service /usr/lib/systemd/system/emerg-shutdown-initramfs.service
  inst_simple /run/emerg-shutdown /emerg-shutdown

  for config_file in /etc/security-misc/emerg-shutdown/*.conf; do
    if [ -f "${config_file}" ]; then
      inst_multiple /etc/security-misc/emerg-shutdown/*.conf
      break
    fi
  done
  for config_file in /usr/local/etc/security-misc/emerg-shutdown/*.conf; do
    if [ -f "${config_file}" ]; then
      inst_multiple /usr/local/etc/security-misc/emerg-shutdown/*.conf
      break
    fi
  done

  mkdir -p "${initdir}/usr/lib/systemd/system/initrd.target.wants"
  ln -s '../emerg-shutdown-initramfs.service' "${initdir}/usr/lib/systemd/system/initrd.target.wants/emerg-shutdown-initramfs.service"
}

## called by dracut
installkernel () {
  hostonly='' instmods evdev
}
