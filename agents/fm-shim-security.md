# fm-shim Security Notes

## Architecture

- **Backend** (`fm-shim-backend.c`): C daemon that claims `org.freedesktop.FileManager1`
  D-Bus name, receives ShowFolders/ShowItems/ShowItemProperties calls, forks a
  Python frontend with the URI arguments and systemd's user environment.
- **Frontend** (`fm_shim_frontend.py`): PyQt5 dialog that validates URIs, resolves
  paths, shows a confirmation prompt, then opens directories via `gio launch`.
- **Build script** (`build-fm-shim-backend`): Compiles the C backend with
  extensive GCC hardening flags.
- **Service** (`fm-shim.service`): systemd user service, Type=notify.

## Rejected Review Suggestions (Kicksecure/security-misc#357)

### pkg-config quoting in build script

pkg-config output is designed to be word-split by shells. Quoting it via bash
arrays just reimplements word splitting manually. The unquoted
`$(pkg-config ...)` is intentional. Upstream has a NOTE comment explaining this.
Do not re-propose this change.

### DBUS_NAME_FLAG_DO_NOT_QUEUE

The D-Bus name queueing behavior is intentional. The IN_QUEUE case withholds
`READY=1` (triggering a systemcheck warning) while remaining in the queue to
reclaim the name ASAP. Exiting immediately would leave the name permanently
unprotected - a worse outcome. Do not re-propose this change.

## Accepted Threat Model

- Local DoS is out of scope.
- systemd user manager environment is trusted.
- Directory replacement / symlink swaps are out of scope (frontend documents this).
- Success replies are returned even on frontend failure (spec safety).
- Python >= 3.13.5 required.
