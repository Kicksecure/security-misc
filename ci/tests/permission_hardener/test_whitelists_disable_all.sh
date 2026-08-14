#!/bin/bash
## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## AI-Assisted

## Regression test: the documented special directive 'whitelists_disable_all=true'
## must be honored, not rejected.
##
## The line contains '=', which is outside the config character-class allow-set.
## The directive check must run BEFORE that character-class validation; otherwise
## the documented line trips "invalid characters" and aborts the whole hardener
## (exit 200), so every other hardening rule in every conf is dropped too.
##
## Drives the REAL script via 'print-policy' with a conf that holds the directive
## plus one ordinary entry, and asserts print-policy exits 0 with the ordinary
## entry present.
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

test_dir="$(mktemp -d -t ph-wda-test.XXXXXX)"
ordinary_file="${test_dir}/ordinary"
touch -- "${ordinary_file}"

config_dir="/etc/permission-hardener.d"
config_file="${config_dir}/zz-ai-whitelists-disable-all-test.conf"
mkdir -p -- "${config_dir}"

## invoked indirectly via 'trap ... EXIT'
# shellcheck disable=SC2317
cleanup() {
  safe-rm -f -- "${config_file}"
  safe-rm -rf -- "${test_dir}"
}
trap cleanup EXIT

{
  printf '%s\n' 'whitelists_disable_all=true'
  printf '%s\n' "${ordinary_file} 0744 root root"
} > "${config_file}"

## The directive line aborts the whole run (exit 200) on the buggy ordering;
## capture the status via an 'if' condition (errexit stays enabled).
if policy_output="$( "${ph_bin}" print-policy 2>/dev/null )"; then
  ph_rc=0
else
  ph_rc=$?
fi

test_status=0
if [ "${ph_rc}" -ne 0 ]; then
  printf '%s\n' "FAIL: print-policy exited ${ph_rc} (directive rejected as invalid characters)." >&2
  test_status=1
fi
if printf '%s\n' "${policy_output}" | grep -qF -- "${ordinary_file}"; then
  printf '%s\n' "PASS: whitelists_disable_all=true accepted; ordinary entry present."
else
  printf '%s\n' "FAIL: ordinary entry '${ordinary_file}' missing from print-policy output." >&2
  test_status=1
fi

if [ "${test_status}" -ne 0 ]; then
  printf '%s\n' "----- print-policy output -----" >&2
  printf '%s\n' "${policy_output}" >&2
fi
exit "${test_status}"
