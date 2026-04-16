# fm-shim Notes

## Accepted Threat Model

- Local DoS is out of scope.
- Directory replacement / symlink swaps are out of scope (frontend documents this).
- Success replies are returned even on frontend failure (spec safety).

## Architecture

- **Backend** (`fm-shim-backend.c`): C daemon that claims `org.freedesktop.FileManager1`
  D-Bus name, receives ShowFolders/ShowItems/ShowItemProperties calls, forks a
  Python frontend with the URI arguments and systemd's user environment.
- **Frontend** (`fm_shim_frontend.py`): PyQt5 dialog that validates URIs, resolves
  paths, shows a confirmation prompt, then opens directories via `gio launch`.
- **Build script** (`build-fm-shim-backend`): Compiles the C backend with
  extensive GCC hardening flags.
- **Service** (`fm-shim.service`): systemd user service, Type=notify.

## D-Bus name acquisition

The fm-shim-backend intentionally uses `DBUS_NAME_FLAG_REPLACE_EXISTING`
**without** `DBUS_NAME_FLAG_DO_NOT_QUEUE`. When the name cannot be acquired,
the process warns and omits `READY=1` so that systemcheck alerts the user.
Hard-failing (via `errx`) removes the service entirely, which is worse than
running in a degraded-but-monitored state. Do not change this to a fatal error.

### DBUS_NAME_FLAG_DO_NOT_QUEUE

The D-Bus name queueing behavior is intentional. The IN_QUEUE case withholds
`READY=1` (triggering a `systemcheck` warning) while remaining in the queue to
reclaim the name ASAP. Exiting immediately would leave the name permanently
unprotected - a worse outcome. Do not re-propose this change.

## Systemd sandboxing on services that spawn user-facing apps

Do not add restrictive systemd sandboxing directives (`ProtectHome`,
`MemoryDenyWriteExecute`, `ProtectSystem=strict`, etc.) to the fm-shim
service. These restrictions are inherited by child processes - the file
manager and anything it launches. `MemoryDenyWriteExecute` may break JIT,
`ProtectHome=read-only` breaks normal file manager operations, etc.

## Closing inherited file descriptors in forked children

Use the `close_range(3, ~0U, CLOSE_RANGE_UNSHARE)` syscall (requires
`#define _GNU_SOURCE` and `#include <linux/close_range.h>`). Do not iterate
`/proc/self/fd` manually.

## D-Bus error replies

When sending D-Bus error replies in multiple places, use the shared helper
function `send_error_message_maybe()` rather than duplicating the pattern
inline.
