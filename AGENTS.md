# Agent Guidelines for security-misc

## General Guidelines

- Check `./agents/` for component-specific notes before reviewing or commenting.
- Upstream repository: Kicksecure/security-misc
- No need to mention accepted/fixed/done things unless there is a specific
  reason why it is needed in memory.

## Component Notes

- [fm-shim](./agents/fm-shim.md) - FileManager1 D-Bus shim (backend + frontend)

## pkg-config quoting in build script

`pkg-config` output is designed to be word-split by shells. Quoting it via bash
arrays just reimplements word splitting manually. The unquoted
`$(pkg-config ...)` is intentional. Upstream has a NOTE comment explaining this.
Do not re-propose this change.

## Accepted Threat Model

- systemd user manager environment is trusted.
- Python >= 3.13.5 required.
