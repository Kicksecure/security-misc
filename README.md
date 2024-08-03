# Enhances miscellaneous security settings

## Kernel hardening

This section is inspired by the Kernel Self Protection Project (KSPP). It
implements all recommended Linux kernel settings by the KSPP and many more.

- https://kernsec.org/wiki/index.php/Kernel_Self_Protection_Project
- https://kspp.github.io/Recommended_Settings

### sysctl

sysctl settings are configured via the `/usr/lib/sysctl.d/990-security-misc.conf`
configuration file.

Significant hardening is applied by default to a myriad of components within kernel
space, user space, core dumps, and swap space.

- Restrict access to kernel addresses through the use of kernel pointers regardless
  of user privileges.

- Restrict access to the kernel logs to `CAP_SYSLOG` as they often contain
  sensitive information.

- Prevent kernel information leaks in the console during boot.

- Restrict eBPF access to `CAP_BPF` and enable associated JIT compiler hardening.

- Restrict loading TTY line disciplines to `CAP_SYS_MODULE`.

- Restrict the `userfaultfd()` syscall to `CAP_SYS_PTRACE`, which reduces the
  likelihood of use-after-free exploits.

- Disable `kexec` as it can be used to replace the running kernel.

- Entirely disable the SysRq key so that the Secure Attention Key (SAK)
  can no longer be utilized. See [documentation](https://www.kicksecure.com/wiki/SysRq).

- Provide the option to disable unprivileged user namespaces as they can lead to
  substantial privilege escalation.

- Restrict kernel profiling and the performance events system to `CAP_PERFMON`.

- Force the kernel to panic on "oopses" that can potentially indicate and thwart
  certain kernel exploitation attempts. Provide the option to reboot immediately
  on a kernel panic.

- Randomize the addresses (ASLR) for mmap base, stack, VDSO pages, and heap.

- Disable asynchronous I/O as `io_uring` has been the source
  of numerous kernel exploits (when using Linux kernel version >= 6.6).

- Restrict usage of `ptrace()` to only processes with `CAP_SYS_PTRACE` as it
  enables programs to inspect and modify other active processes. Provide the
  option to entirely disable the use of `ptrace()` for all processes.

- Prevent hardlink and symlink TOCTOU races in world-writable directories.

- Disallow unintentional writes to files in world-writable directories unless
  they are owned by the directory owner to mitigate some data spoofing attacks.

- Increase the maximum number of memory map areas a process is able to utilize.

- Disable core dump files and prevent their creation. If core dump files are
  enabled, they will be named based on `core.PID` instead of the default `core`.

- Limit the copying of potentially sensitive content in memory to the swap device.

Various networking components of the TCP/IP stack are hardened for IPv4/6.

- Enable TCP SYN cookie protection to assist against SYN flood attacks.

- Protect against TCP time-wait assassination hazards.

- Enable reverse path filtering (source validation) of packets received
  from all interfaces to prevent IP spoofing.

- Disable ICMP redirect acceptance and redirect sending messages to
  prevent man-in-the-middle attacks and minimize information disclosure. If
  ICMP redirect messages are permitted, only do so from approved gateways.

- Ignore ICMP echo requests to prevent clock fingerprinting and Smurf attacks.

- Ignore bogus ICMP error responses.

- Disable source routing which allows users to redirect network traffic that
  can result in man-in-the-middle attacks.

- Do not accept IPv6 router advertisements and solicitations.

- Provide the option to disable SACK and DSACK as they have historically been
  a known vector for exploitation.

- Disable TCP timestamps as they can allow detecting the system time.

- Provide the option to log packets with impossible source or destination
  addresses to enable further inspection and analysis.

- Provide the option to enable IPv6 Privacy Extensions.

### mmap ASLR

- The bits of entropy used for mmap ASLR are maxed out via
  `/usr/libexec/security-misc/mmap-rnd-bits` (set to the values of
  `CONFIG_ARCH_MMAP_RND_BITS_MAX` and `CONFIG_ARCH_MMAP_RND_COMPAT_BITS_MAX`
  that the kernel was built with), therefore improving its effectiveness.

### Boot parameters

Mitigations for known CPU vulnerabilities are enabled in their strictest form
and simultaneous multithreading (SMT) is disabled. See the
`/etc/default/grub.d/40_cpu_mitigations.cfg` configuration file.

Boot parameters relating to kernel hardening, DMA mitigations, and entropy
generation are outlined in the `/etc/default/grub.d/40_kernel_hardening.cfg`
configuration file.

- Disable merging of slabs with similar size, which reduces the risk of
  triggering heap overflows and limits influencing slab cache layout.

- Provides option to enable sanity checks and red zoning via slab debugging.
  Not reccommened due to implicit disabling of kernel pointer hashing.

- Enable memory zeroing at both allocation and free time, which mitigates some
  use-after-free vulnerabilities by erasing sensitive information in memory.

- Enable the kernel page allocator to randomize free lists to limit some data
  exfiltration and ROP attacks, especially during the early boot process.

- Enable kernel page table isolation to increase KASLR effectiveness and also
  mitigate the Meltdown CPU vulnerability.

- Enable randomization of the kernel stack offset on syscall entries to harden
  against memory corruption attacks.

- Disable vsyscalls as they are vulnerable to ROP attacks and have now been
  replaced by vDSO.

- Restrict access to debugfs by not registering the file system since it can
  contain sensitive information.

- Force kernel panics on "oopses" to potentially indicate and thwart certain
  kernel exploitation attempts.

- Provide the option to modify machine check exception handler.

- Provide the option to use kCFI as the default CFI implementation since it may be
  slightly more resilient to attacks that are able to write arbitrary executables
  in memory (when using Linux kernel version >= 6.2).

- Provide the option to disable support for all x86 processes and syscalls to reduce
  attack surface (when using Linux kernel version >= 6.7).

- Enable strict IOMMU translation to protect against DMA attacks and disable
  the busmaster bit on all PCI bridges during the early boot process.

- Do not credit the CPU or bootloader as entropy sources at boot in order to
  maximize the absolute quantity of entropy in the combined pool.

- Obtain more entropy at boot from RAM as the runtime memory allocator is
  being initialized.

- Provide the option to disable the entire IPv6 stack to reduce attack surface.

Disallow sensitive kernel information leaks in the console during boot. See
the `/etc/default/grub.d/41_quiet_boot.cfg` configuration file.

### Kernel Modules

#### Kernel Module Signature Verification

Not yet implemented due to issues:

- https://forums.whonix.org/t/enforce-kernel-module-software-signature-verification-module-signing-disallow-kernel-module-loading-by-default/7880/64
- https://github.com/dell/dkms/issues/359

See:

- `/etc/default/grub.d/40_signed_modules.cfg`

#### Disables the loading of new modules to the kernel after the fact

Not yet implemented due to issues:

- https://github.com/Kicksecure/security-misc/pull/152

A systemd service dynamically sets the kernel parameter `modules_disabled` to 1,
preventing new modules from being loaded. Since this isn't configured directly
within systemctl, it does not break the loading of legitimate and necessary
modules for the user, like drivers etc., given they are plugged in on startup.

#### Blacklist and disable kernel modules

Conntrack: Deactivates Netfilter's connection tracking helper module which
increases kernel attack surface by enabling superfluous functionality such
as IRC parsing in the kernel. See `/etc/modprobe.d/30_security-misc_conntrack.conf`.

Certain kernel modules are blacklisted by default to reduce attack surface via
`/etc/modprobe.d/30_security-misc_blacklist.conf`. Blacklisting prevents kernel
modules from automatically starting.

- CD-ROM/DVD: Blacklist modules required for CD-ROM/DVD devices.

- Framebuffer Drivers: Blacklisted as they are well-known to be buggy, cause
  kernel panics, and are generally only used by legacy devices.

- Miscellaneous: Blacklist an assortment of other modules to prevent them from
  automatically loading.

Specific kernel modules are entirely disabled to reduce attack surface via
`/etc/modprobe.d/30_security-misc_disable.conf`. Disabling prohibits kernel
modules from starting. This approach should not be considered comprehensive;
rather, it is a form of badness enumeration. Any potential candidates for future
disabling should first be blacklisted for a suitable amount of time.

- Optional - Bluetooth: Disabled to reduce attack surface.

- Optional - CPU MSRs: Disabled as can be abused to write to arbitrary memory.

- File Systems: Disable uncommon and legacy file systems.

- FireWire (IEEE 1394): Disabled as they are often vulnerable to DMA attacks.

- GPS: Disable GPS-related modules such as those required for Global Navigation
  Satellite Systems (GNSS).

- Optional - Intel Management Engine (ME): Provides some disabling of the interface
  between the Intel ME and the OS. May lead to breakages in places such as security,
  power management, display, and DRM. See discussion: https://github.com/Kicksecure/security-misc/issues/239

- Intel Platform Monitoring Technology Telemetry (PMT): Disable some functionality
  of the Intel PMT components.

- Network File Systems: Disable uncommon and legacy network file systems.

- Network Protocols: A wide array of uncommon and legacy network protocols and drivers
  are disabled.

- Miscellaneous: Disable an assortment of other modules such as those required
  for amateur radio, floppy disks, and vivid.

- Thunderbolt: Disabled as they are often vulnerable to DMA attacks.

- Optional - USB Video Device Class: Disables the USB-based video streaming driver for
  devices like some webcams and digital camcorders.

### Other

- A systemd service clears the System.map file on boot as these contain kernel
  pointers. The file is completely overwritten with zeroes to ensure it cannot
  be recovered. See:

`/etc/kernel/postinst.d/30_remove-system-map`

`/lib/systemd/system/remove-system-map.service`

`/usr/libexec/security-misc/remove-system.map`

- Coredumps are disabled as they may contain important information such as
  encryption keys or passwords. See:

`/etc/security/limits.d/30_security-misc.conf`

`/etc/sysctl.d/30_security-misc.conf`

`/lib/systemd/coredump.conf.d/30_security-misc.conf`

- An initramfs hook sets the sysctl values in `/etc/sysctl.conf` and
  `/etc/sysctl.d` before init is executed so sysctl hardening is enabled as
  early as possible. This is implemented for `initramfs-tools` only because
  this is not needed for `dracut` as `dracut` does that by default, at
  least on `systemd` enabled systems. Not researched for non-`systemd` systems
  by the author of this part of the readme.

## Network hardening

Not yet implemented due to issues:

- https://github.com/Kicksecure/security-misc/pull/145

- https://github.com/Kicksecure/security-misc/issues/184

- Unlike version 4, IPv6 addresses can provide information not only about the
  originating network but also the originating device. We prevent this from
  happening by enabling the respective privacy extensions for IPv6.

- In addition, we deny the capability to track the originating device in the
  network at all, by using randomized MAC addresses per connection by
  default.

See:

- `/usr/lib/NetworkManager/conf.d/80_ipv6-privacy.conf`
- `/usr/lib/NetworkManager/conf.d/80_randomize-mac.conf`
- `/usr/lib/systemd/networkd.conf.d/80_ipv6-privacy-extensions.conf`

## Bluetooth Hardening

### Bluetooth Status: Enabled but Defaulted to Off

- **Default Behavior**: Although Bluetooth capability is 'enabled' in the kernel, security-misc deviates from the usual behavior by starting with Bluetooth turned off at system start. This setting remains until the user explicitly opts to activate Bluetooth.

- **User Control**: Users have the freedom to easily switch Bluetooth on and off in the usual way, exercising their own discretion. This can be done via the Bluetooth toggle through the usual way, that is either through GUI settings application or command line commands.

- **Enhanced Privacy Settings**: We enforce more private defaults for Bluetooth connections. This includes the use of private addresses and strict timeout settings for discoverability and visibility.

- **Security Considerations**: Despite these measures, it's important to note that Bluetooth technology, by its nature, may still be prone to exploits due to its history of security vulnerabilities. Thus, we recommend users to opt-out of using Bluetooth when possible.

### Configuration Details

- See configuration: `/etc/bluetooth/30_security-misc.conf`
- For more information and discussion: [GitHub Pull Request](https://github.com/Kicksecure/security-misc/pull/145)

### Understanding Bluetooth Terms

- **Disabling Bluetooth**: This means the absence of the Bluetooth kernel module. When disabled, Bluetooth is non-existent in the system - it cannot be seen, set, configured, or interacted with in any way.

- **Turning Bluetooth On/Off**: This refers to a software toggle. Normally, on Debian systems, Bluetooth is 'on' when the system boots up. It actively searches for known devices to auto-connect and may be discoverable or visible under certain conditions. Our default ensures that Bluetooth is off on startup. However, it remains 'enabled' in the kernel, meaning the kernel can use the Bluetooth protocol and has the necessary modules.

### Quick Toggle Guide

- **Turning Bluetooth On**: Simply click the Bluetooth button in the settings application or on the tray, and switch the toggle. It's a straightforward action that can be completed in less than a second.

- **Turning Bluetooth Off**: Follow the same procedure as turning it on but switch the toggle to the off position.

## Entropy collection improvements

- The `jitterentropy_rng` kernel module is loaded as early as possible during
  boot to gather more entropy via the
  `/usr/lib/modules-load.d/30_security-misc.conf` configuration file.

- Distrusts the CPU for initial entropy at boot as it is not possible to
  audit, may contain weaknesses or a backdoor. Similarly, do not credit the
  bootloader seed for initial entropy. For references, see:
  `/etc/default/grub.d/40_kernel_hardening.cfg`

- Gathers more entropy during boot if using the linux-hardened kernel patch.

## Restrictive mount options

A systemd service is triggered on boot to remount all sensitive partitions and
directories with significantly more secure hardened mount options. Since this
would require manual tuning for a given specific system, we handle it by
creating a very solid configuration file for that very system on package
installation.

Not enabled by default yet. In development. Help welcome.

- https://www.kicksecure.com/wiki/Dev/remount-secure
- https://github.com/Kicksecure/security-misc/issues/157
- https://forums.whonix.org/t/re-mount-home-and-other-with-noexec-and-nosuid-among-other-useful-mount-options-for-better-security/

## Root access restrictions

- `su` is restricted to only users within the group `sudo` which prevents
  users from using `su` to gain root access or to switch user accounts -
  `/usr/share/pam-configs/wheel-security-misc` (which results in a change in
  file `/etc/pam.d/common-auth`).

- Add user `root` to group `sudo`. This is required due to the above
  restriction so that logging in from a virtual console is still possible -
  `debian/security-misc.postinst`

- Abort login for users with locked passwords -
  `/usr/libexec/security-misc/pam-abort-on-locked-password`.

- Logging into the root account from a virtual, serial, or other console is
  prevented by shipping an existing and empty `/etc/securetty` file (deletion
  of `/etc/securetty` has a different effect).

This package does not yet automatically lock the root account password. It is
not clear if this would be sane in such a package, although it is recommended to
lock and expire the root account.

In new Kicksecure builds, the root account will be locked by package
dist-base-files.

See:

- https://www.kicksecure.com/wiki/Root
- https://www.kicksecure.com/wiki/Dev/Permissions
- https://forums.whonix.org/t/restrict-root-access/7658

However, a locked root password will break rescue and emergency shell.
Therefore, this package enables passwordless rescue and emergency shell. This is
the same solution that Debian will likely adopt for the Debian installer:
https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=802211

See:

- `/etc/systemd/system/emergency.service.d/override.conf`
- `/etc/systemd/system/rescue.service.d/override.conf`

Adverse security effects can be prevented by setting up BIOS password
protection, GRUB password protection, and/or full disk encryption.

## Console lockdown

This uses pam_access to allow members of group `console` to use the console but
restrict everyone else (except members of group `console-unrestricted`) from
using the console with ancient, unpopular login methods such as `/bin/login` over
networks as this might be exploitable. (CVE-2001-0797)

This is not enabled by default in this package since this package does not know
which users should be added to group 'console' and thus, would break console access.

See:

- `/usr/share/pam-configs/console-lockdown-security-misc`
- `/etc/security/access-security-misc.conf`

## Brute force attack protection

User accounts are locked after 50 failed login attempts using `pam_faillock`.

Informational output during Linux PAM:

- Show failed and remaining password attempts.
- Document unlock procedure if Linux user account got locked.
- Point out that there is no password feedback for `su`.
- Explain locked root account if locked.

See:

- `/usr/share/pam-configs/tally2-security-misc`
- `/usr/libexec/security-misc/pam-info`
- `/usr/libexec/security-misc/pam-abort-on-locked-password`

## Access rights restrictions

### Strong user account separation

#### Permission Lockdown

Read, write, and execute access for "others" are removed during package
installation, upgrade, or PAM `mkhomedir` for all users who have home folders in
`/home` by running, for example:

```
chmod o-rwx /home/user
```

This will be done only once per folder in `/home` so users who wish to relax
file permissions are free to do so. This is to protect files in a home folder
that were previously created with lax file permissions prior to the installation
of this package.

See:

- `debian/security-misc.postinst`
- `/usr/libexec/security-misc/permission-lockdown`
- `/usr/share/pam-configs/mkhomedir-security-misc`

#### umask

Default `umask` is set to `027` for files created by non-root users such as
user `user`. Broken. Disabled. See:

* https://github.com/Kicksecure/security-misc/issues/184

This is done using the PAM module `pam_mkhomedir.so umask=027`.

This means files created by non-root users cannot be read by other non-root
users by default. While Permission Lockdown already protects the `/home` folder,
this protects other folders such as `/tmp`.

`group` read permissions are not removed. This is unnecessary due to Debian's
use of User Private Groups (UPGs). See also:
https://wiki.debian.org/UserPrivateGroups

Default `umask` is unchanged for root because then configuration files created
in `/etc` by the system administrator would be unreadable by "others" and break
applications. Examples include `/etc/firefox-esr` and `/etc/thunderbird`.

See:

- `/usr/share/pam-configs/umask-security-misc`

### SUID / SGID removal and permission hardening

#### SUID / SGID removal

A systemd service removes SUID / SGID bits from non-essential binaries as these
are often used in privilege escalation attacks.

#### File permission hardening

Various file permissions are reset with more secure and hardened defaults. These
include but are not limited to:

- Limiting `/home` and `/root` to the root only.
- Limiting crontab to root as well as all the configuration files for cron.
- Limiting the configuration for cups and ssh.
- Protecting the information of sudoers from others.
- Protecting various system-relevant files and modules.

##### permission-hardener

`permission-hardener` removes SUID / SGID bits from non-essential binaries as
these are often used in privilege escalation attacks. It is enabled by default
and applied at security-misc package installation and upgrade time.

There is also an optional systemd unit which does the same at boot time that
can be enabled by running `systemctl enable permission-hardener.service` as
root. The hardening at boot time is not the default because this slows down
the boot process too much.

See:

* `/usr/bin/permission-hardener`
* `debian/security-misc.postinst`
* `/lib/systemd/system/permission-hardener.service`
* `/etc/permission-hardener.d`
* https://forums.whonix.org/t/disable-suid-binaries/7706
* https://www.kicksecure.com/wiki/SUID_Disabler_and_Permission_Hardener

### Access rights relaxations

This is not enabled yet because hidepid is not enabled by default.

Calls to `pkexec` are redirected to `lxqt-sudo` because `pkexec` is
incompatible with `hidepid=2`.

See:

* `/usr/bin/pkexec.security-misc`
* https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=860040
* https://forums.whonix.org/t/cannot-use-pkexec/8129

## Application-specific hardening

- Enables "`apt-get --error-on=any`" which makes apt exit non-zero for
  transient failures. - `/etc/apt/apt.conf.d/40error-on-any`.
- Enables APT seccomp-BPF sandboxing - `/etc/apt/apt.conf.d/40sandbox`.
- Deactivates previews in Dolphin.
- Deactivates previews in Nautilus -
  `/usr/share/glib-2.0/schemas/30_security-misc.gschema.override`.
- Deactivates thumbnails in Thunar.
  - Rationale: lower attack surface when using the file manager
  - https://forums.whonix.org/t/disable-preview-in-file-manager-by-default/18904
- Thunderbird is hardened with the following options:
  - Displays domain names in punycode to prevent IDN homograph attacks (a
    form of phishing).
  - Strips email client information from sent email headers.
  - Strips user time information from sent email headers by replacing the
    originating time zone with UTC and rounding the timestamp to the nearest
    minute.
  - Disables scripting when viewing PDF files.
  - Disables implicit outgoing connections.
  - Disables all and any kind of telemetry.
- Security and privacy enhancements for gnupg's config file
  `/etc/skel/.gnupg/gpg.conf`. See also:
  - https://raw.github.com/ioerror/torbirdy/master/gpg.conf
  - https://github.com/ioerror/torbirdy/pull/11

### Project scope of application-specific hardening

Added in December 2023.

Before sending pull requests to harden arbitrary applications, please note the
scope of security-misc is limited to default installed applications in
Kicksecure and Whonix. This includes:

- Thunderbird, VLC Media Player, KeePassXC
- Debian Specific System Components (APT, DPKG)
- System Services (NetworkManager IPv6 privacy options, MAC address
  randomization)
- Actually used development utilities such as `git`.

It will not be possible to review and merge "1500" settings profiles for
arbitrary applications outside of this context.

The main objective of security-misc is to harden Kicksecure and its derivatives,
such as Whonix, by implementing robust security settings. It's designed to be
compatible with Debian, reflecting a commitment to clean implementation and
sound design principles. However, it's important to note that security-misc is a
component of Kicksecure, not a substitute for it. The intention isn't to
recreate Kicksecure within security-misc. Instead, specific security
enhancements, like recommending a curated list of security-focused
default packages (e.g., `libpam-tmpdir`), should be integrated directly into
those appropriate areas of Kicksecure (e.g. `kicksecure-meta-packages`).

Discussion: https://github.com/Kicksecure/security-misc/issues/154

### Development philosophy

Added in December 2023.

Maintainability is a key priority \[1\]. Before modifying settings in the
downstream security-misc, it's essential to first engage with upstream
developers to propose these changes as defaults. This step should only be
bypassed if there's a clear, prior indication from upstream that such changes
won't be accepted. Additionally, before implementing any workarounds, consulting
with upstream is necessary to avoid future unmaintainable complexity.

If debugging features are disabled, pull requests won't be merged until there is
a corresponding pull request for the debug-misc package to re-enable these. This
is to avoid configuring the system into a corner where it can no longer be
debugged.

\[1\] https://www.kicksecure.com/wiki/Dev/maintainability

## Opt-in hardening

Some hardening is opt-in as it causes too much breakage to be enabled by
default.

- An optional systemd service mounts `/proc` with `hidepid=2` at boot to
  prevent users from seeing another user's processes. This is disabled by
  default because it is incompatible with `pkexec`. It can be enabled by
  executing `systemctl enable proc-hidepid.service` as root.

- A systemd service restricts `/proc/cpuinfo`, `/proc/bus`, `/proc/scsi`, and
  `/sys` to the root user. This hides a lot of hardware identifiers from
  unprivileged users and increases security as `/sys` exposes a lot of
  information that shouldn't be accessible to unprivileged users. As this will
  break many things, it is disabled by default and can optionally be enabled
  by executing `systemctl enable hide-hardware-info.service` as root.

## Miscellaneous

- Hardened malloc compatibility for haveged workaround
  `/lib/systemd/system/haveged.service.d/30_security-misc.conf`

- Set `dracut` `reproducible=yes` setting

## Legal

`/usr/lib/issue.d/20_security-misc.issue`

https://github.com/Kicksecure/security-misc/pull/167

## Related

-   Linux Kernel Runtime Guard (LKRG)
-   tirdad - TCP ISN CPU Information Leak Protection.
-   Kicksecure (TM) - a security-hardened Linux Distribution
-   And more.
-   https://www.kicksecure.com/wiki/Linux_Kernel_Runtime_Guard_LKRG
-   https://github.com/Kicksecure/tirdad
-   https://www.kicksecure.com
-   https://github.com/Kicksecure

## Discussion

Happening primarily in forums.

https://forums.whonix.org/t/kernel-hardening/7296

## How to install `security-misc`

See https://www.kicksecure.com/wiki/Security-misc#install

## How to Build deb Package from Source Code

Can be build using standard Debian package build tools such as:

    dpkg-buildpackage -b

See instructions. (Replace `generic-package` with the actual name of this
package `security-misc`.)

-   **A)**
    [easy](https://www.kicksecure.com/wiki/Dev/Build_Documentation/generic-package/easy),
    *OR*
-   **B)** [including verifying software
    signatures](https://www.kicksecure.com/wiki/Dev/Build_Documentation/generic-package)

## Contact

-   [Free Forum Support](https://forums.kicksecure.com)
-   [Professional Support](https://www.kicksecure.com/wiki/Professional_Support)

## Donate

`security-misc` requires [donations](https://www.kicksecure.com/wiki/Donate) to
stay alive!
