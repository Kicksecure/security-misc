# Agent Guidelines for security-misc

## fm-shim

### D-Bus name acquisition

The fm-shim-backend intentionally uses `DBUS_NAME_FLAG_REPLACE_EXISTING`
**without** `DBUS_NAME_FLAG_DO_NOT_QUEUE`. When the name cannot be acquired,
the process warns and omits `READY=1` so that systemcheck alerts the user.
Hard-failing (via `errx`) removes the service entirely, which is worse than
running in a degraded-but-monitored state. Do not change this to a fatal error.

### Systemd sandboxing on services that spawn user-facing apps

Do not add restrictive systemd sandboxing directives (`ProtectHome`,
`MemoryDenyWriteExecute`, `ProtectSystem=strict`, etc.) to the fm-shim
service. These restrictions are inherited by child processes — the file
manager and anything it launches. `MemoryDenyWriteExecute` breaks JIT,
`ProtectHome=read-only` breaks normal file manager operations, etc.

### Closing inherited file descriptors in forked children

Use the `close_range(3, ~0U, CLOSE_RANGE_UNSHARE)` syscall (requires
`#define _GNU_SOURCE` and `#include <linux/close_range.h>`). Do not iterate
`/proc/self/fd` manually.

### D-Bus error replies

When sending D-Bus error replies in multiple places, extract a shared helper
function (e.g. `send_error_message_maybe()`) rather than duplicating the
pattern inline.
