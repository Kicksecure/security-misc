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

## A filename whose space-split yields a BARE octal chunk ('744'). The mode
## must be anchored from the RIGHT: a left-to-right scan anchors on that chunk
## instead of the real mode at the end, fails the field-count check, and aborts
## the whole hardener (exit 200) rather than parsing the entry.
octal_chunk_file="${test_dir}/a 744 name"
touch -- "${octal_chunk_file}"

## A space-free filename with a 4-option (capability) tail whose OWNER is a
## numeric id that looks octal ('0755'). Right-anchoring must NOT treat that
## owner as the mode: it would fold the real mode into the filename, the folded
## path does not exist, and the entry is silently dropped -- leaving the file
## un-hardened. The line is already well formed, so no recovery must happen.
numeric_owner_file="${test_dir}/numowner"
touch -- "${numeric_owner_file}"

## The mirror-image of the numeric-owner case: a SPACED filename whose second
## component (field index 1) is a bare octal, with a 3-field tail. Here field 1
## is NOT the mode, so recovery must happen. Existence disambiguates: the spaced
## name exists, its no-recovery prefix does not.
octal_second_file="${test_dir}/a 744"
touch -- "${octal_second_file}"

## Six fields: a SPACED filename plus a numeric octal-looking owner and a
## capability tail. The rightmost octal candidate (field_count-3) is the owner,
## not the mode; anchoring there folds the mode into the filename and drops the
## entry. Existence must select field_count-4 (the real mode) instead.
numeric_owner_spaced_file="${test_dir}/x y"
touch -- "${numeric_owner_spaced_file}"

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

## mode-form entries: <filename> <mode> <owner> <group> [capability]
{
  printf '%s\n' "${spaced_file} 0744 root root"
  printf '%s\n' "${octal_chunk_file} 0744 root root"
  printf '%s\n' "${numeric_owner_file} 0744 0755 root cap_net_raw"
  printf '%s\n' "${octal_second_file} 0644 root root"
  printf '%s\n' "${numeric_owner_spaced_file} 0744 0755 root cap_net_raw"
} > "${config_file}"

## A parse failure on any line aborts the whole run with exit 200; capture the
## status via an 'if' condition (errexit stays enabled) so the failure is
## reported cleanly rather than aborting the test.
if policy_output="$( "${ph_bin}" print-policy 2>/dev/null )"; then
  ph_rc=0
else
  ph_rc=$?
fi

test_status=0
if [ "${ph_rc}" -ne 0 ]; then
  printf '%s\n' "FAIL: print-policy exited ${ph_rc} (parse aborted the whole run)." >&2
  test_status=1
fi
## print-policy prints tab-separated columns (File<TAB>User<TAB>...), so match
## each filename as the whole first field (trailing TAB). A bare substring match
## would let '/a 744' spuriously match the '/a 744 name' entry.
for expected_file in "${spaced_file}" "${octal_chunk_file}" "${numeric_owner_file}" "${octal_second_file}" "${numeric_owner_spaced_file}"; do
  if printf '%s\n' "${policy_output}" | grep -qF -- "${expected_file}"$'\t'; then
    printf '%s\n' "PASS: filename '${expected_file}' parsed and present in policy."
  else
    printf '%s\n' "FAIL: filename '${expected_file}' missing from print-policy output." >&2
    test_status=1
  fi
done

if [ "${test_status}" -ne 0 ]; then
  printf '%s\n' "----- print-policy output -----" >&2
  printf '%s\n' "${policy_output}" >&2
fi
exit "${test_status}"
