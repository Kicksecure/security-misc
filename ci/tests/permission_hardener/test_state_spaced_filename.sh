#!/bin/bash
## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## AI-Assisted

## Regression test: a hardened file whose path contains spaces must be
## un-hardenable via 'disable'.
##
## load_state_without_policy() reads the dpkg-statoverride state DB, one entry
## per line as 'owner group mode path'. A plain 4-field split drops any spaced
## path, so 'disable' never finds the entry and the file can never be restored.
##
## Seeds one spaced entry (mode 0744) into the state DB, sets the file to 0600,
## runs 'disable', and asserts the mode is restored to 0744 -- which only
## happens if load_state_without_policy read the spaced path back.
##
## Requires root: writes the state DB and chmod/chowns the target file.

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

## Must match store_dir in the script under test.
existing_mode_admindir='/var/lib/permission-hardener-v2/existing_mode'
mkdir -p -- "${existing_mode_admindir}"

test_dir="$(mktemp -d -t ph-state-test.XXXXXX)"
spaced_file="${test_dir}/spaced tool"
touch -- "${spaced_file}"
chmod 0600 -- "${spaced_file}"

## invoked indirectly via 'trap ... EXIT'
# shellcheck disable=SC2317
cleanup() {
  ## undo touches the master and new_mode DBs, not existing_mode, so remove the
  ## seeded entry explicitly.
  dpkg-statoverride --admindir "${existing_mode_admindir}" --remove \
    "${spaced_file}" >/dev/null 2>&1 || true
  safe-rm -rf -- "${test_dir}"
}
trap cleanup EXIT

## Seed the state DB: this is the record 'enable' would have written.
dpkg-statoverride --admindir "${existing_mode_admindir}" --add \
  root root 0744 "${spaced_file}"

"${ph_bin}" disable "${spaced_file}" >/dev/null 2>&1 || true

actual_mode="$(stat -c '%a' -- "${spaced_file}")"
if [ "${actual_mode}" = '744' ]; then
  printf '%s\n' "PASS: spaced-path state entry read back; mode restored to 744."
  exit 0
fi

printf '%s\n' "FAIL: mode is '${actual_mode}', expected '744' -- spaced state entry not read back, file cannot be un-hardened." >&2
exit 1
