#!/bin/bash

## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## AI-Assisted

## CodeQL pre-init source-tree prep.
##
## This repo names installable files with a '#<package-tag>' suffix
## (Kicksecure/genmkfile convention - the suffix routes the file to
## the correct Debian binary package at build time). The suffix
## breaks two CodeQL paths:
##
##   * Python extractor discovers source files by the '.py'
##     extension; 'foo.py#security-misc-shared' is invisible.
##   * gcc selects driver behavior by extension; 'foo.c#tag' is
##     treated by ld as a linker script ("file format not
##     recognized"). The compile helpers used by ci/codeql-build.sh
##     receive their .c source by path argument, so a clean
##     '.c'-extension symlink is required here too.
##
## Walk the tracked file list and create same-directory symlinks
## without the '#tag' suffix so both extractors and gcc see the
## source under its conventional name. Symlinks point at the
## original tagged file via basename so the link resolves regardless
## of how the tree is later moved.

set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
shopt -s inherit_errexit
shopt -s shift_verbose

repo_root="$(git rev-parse --show-toplevel)"
cd -- "${repo_root}"

linked=0
skipped=0
while IFS= read -r tagged; do
  ## Only files where the suffix immediately follows a known
  ## source-language extension. Other tagged files (config files,
  ## scripts without an extension, etc.) need no rename.
  case "${tagged}" in
    *'.py#'*|*'.c#'*|*'.h#'*)
      ;;
    *)
      continue
      ;;
  esac

  clean="${tagged%#*}"

  ## Do not clobber a real (untagged) file.
  if [ -e "${clean}" ] && [ ! -L "${clean}" ]; then
    skipped=$((skipped + 1))
    continue
  fi

  ## Symlink target must be relative to the link's directory.
  target="$(basename -- "${tagged}")"
  ln -snf -- "${target}" "${clean}"
  linked=$((linked + 1))
done < <(git ls-files -- '*.py#*' '*.c#*' '*.h#*')

printf 'codeql-prepare: linked=%d skipped=%d\n' "${linked}" "${skipped}"
