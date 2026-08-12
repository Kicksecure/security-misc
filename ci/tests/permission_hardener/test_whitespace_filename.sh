#!/bin/bash
## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## AI-Assisted

## Regression test: permission-hardener must parse a config filename that
## contains spaces.
##
## load_state() recovers the filename by reading the option fields from the
## right (a trailing whitelist keyword, or the mode/owner/group[/capability]
## tail anchored by the octal mode). A space in the filename must NOT split it
## into the wrong fields -- that drops the entry silently, leaving a SUID
## binary un-hardened.
##
## Drives the REAL script via 'print-policy' with a mode-form entry
## (<filename> <mode> <owner> <group>) whose filename contains a space, and
## asserts the recovered filename appears in the printed policy.
##
## Requires root: writes a temporary config under /etc/permission-hardener.d/
## and needs helper-scripts installed (sourced by permission-hardener).

set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
shopt -s inherit_errexit
shopt -s shift_verbose

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
ph_bin="${PERMISSION_HARDENER_BIN:-${repo_root}/usr/bin/permission-hardener#security-misc-shared}"

if [ ! -f "${ph_bin}" ]; then
  printf '%s\n' "FAIL: permission-hardener not found at '${ph_bin}'." >&2
  exit 1
fi

test_dir="$(mktemp -d -t ph-ws-test.XXXXXX)"
## The space in the directory name is the property under test.
spaced_file="${test_dir}/some space/binary"
mkdir -p -- "${test_dir}/some space"
touch -- "${spaced_file}"

config_dir="/etc/permission-hardener.d"
config_file="${config_dir}/zz-ai-whitespace-regression-test.conf"
mkdir -p -- "${config_dir}"

## invoked indirectly via 'trap ... EXIT'
# shellcheck disable=SC2317
cleanup() {
  safe-rm -f -- "${config_file}"
  safe-rm -rf -- "${test_dir}"
}
trap cleanup EXIT

## mode-form entry: <filename> <mode> <owner> <group>
printf '%s\n' "${spaced_file} 0744 root root" > "${config_file}"

policy_output="$( "${ph_bin}" print-policy )"

if printf '%s\n' "${policy_output}" | grep -qF -- "${spaced_file}"; then
  printf '%s\n' "PASS: space-containing filename parsed and present in policy."
  exit 0
fi

printf '%s\n' "FAIL: space-containing filename '${spaced_file}' missing from print-policy output." >&2
printf '%s\n' "----- print-policy output -----" >&2
printf '%s\n' "${policy_output}" >&2
exit 1
