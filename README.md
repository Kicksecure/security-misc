# Enhances miscellaneous security settings

## Kernel hardening

This section is inspired by the Kernel Self Protection Project (KSPP). It
attempts to implement all recommended Linux kernel settings by the KSPP and
many more sources.

- https://kspp.github.io/Recommended_Settings
- https://github.com/KSPP/kspp.github.io

### sysctl

sysctl settings are configured via the `/usr/lib/sysctl.d/990-security-misc.conf`
configuration file and significant hardening is applied to a myriad of components.

#### Kernel space

- Restrict access to kernel addresses through the use of kernel pointers regardless
  of user privileges.

- Restrict access to the kernel logs to `CAP_SYSLOG` as they often contain
  sensitive information.

- Prevent kernel information leaks in the console during boot.

- Restrict usage of `bpf()` to `CAP_BPF` to prevent the loading of BPF programs
  by unprivileged users.

- Restrict loading TTY line disciplines to `CAP_SYS_MODULE`.

- Restrict the `userfaultfd()` syscall to `CAP_SYS_PTRACE`, which reduces the
  likelihood of use-after-free exploits.

- Disable `kexec` as it can be used to replace the running kernel.

- Entirely disable the SysRq key so that the Secure Attention Key (SAK)
  can no longer be utilized. See [documentation](https://www.kicksecure.com/wiki/SysRq).

- Optional - Disable all use of user namespaces.

- Optional - Restrict user namespaces to `CAP_SYS_ADMIN` as they can lead to substantial
  privilege escalation.

- Restrict kernel profiling and the performance events system to `CAP_PERFMON`.

- Force the kernel to immediately panic on both "oopses" (which can potentially indicate
  and thwart certain kernel exploitation attempts) and kernel warnings in the `WARN()` path.

- Force immediate system reboot on the occurrence of a single kernel panic, reducing the
  risk and impact of denial of service attacks and both cold and warm boot attacks.

- Disable the use of legacy TIOCSTI operations which can be used to inject keypresses.

- Disable asynchronous I/O as `io_uring` has been the source of numerous kernel exploits.

#### User space

- Restrict usage of `ptrace()` to only processes with `CAP_SYS_PTRACE` as it
  enables programs to inspect and modify other active processes. Optional - Disable
  usage of `ptrace()` by all processes.

- Maximize the bits of entropy used for mmap ASLR across all CPU architectures.

- Prevent hardlink and symlink TOCTOU races in world-writable directories.

- Disallow unintentional writes to files in world-writable directories unless
  they are owned by the directory owner to mitigate some data spoofing attacks.

- Randomize the addresses (ASLR) for mmap base, stack, VDSO pages, and heap.

- Raise the minimum address a process can request for memory mapping to 64KB to
  protect against kernel null pointer dereference vulnerabilities.

- Increase the maximum number of memory map areas a process is able to utilize to 1,048,576.

- Optional - Disallow registering interpreters for various (miscellaneous) binary formats based
  on a magic number or their file extension to prevent unintended code execution.
  See issue: https://github.com/Kicksecure/security-misc/issues/267

#### Core dumps

- Disable core dump files and prevent their creation. If core dump files are
  enabled, they will be named based on `core.PID` instead of the default `core`.

#### Swap space

- Limit the copying of potentially sensitive content in memory to the swap device.

#### Networking

- Enable hardening of the BPF JIT compiler protect against JIT spraying.

- Enable TCP SYN cookie protection to assist against SYN flood attacks.

- Protect against TCP time-wait assassination hazards.

- Enable reverse path filtering (source validation) of packets received
  from all interfaces to prevent IP spoofing.

- Disable ICMP redirect acceptance and redirect sending messages to prevent
  man-in-the-middle attacks and minimize information disclosure.

- Deny sending and receiving shared media redirects to reduce the risk of IP
  spoofing attacks.

- Enable ARP filtering to mitigate some ARP spoofing and ARP cache poisoning attacks.

- Respond to ARP requests only if the target IP address is  on-link,
  preventing some IP spoofing attacks.

- Drop gratuitous ARP packets to prevent ARP cache poisoning via
  man-in-the-middle and denial-of-service attacks.

- Ignore ICMP echo requests to prevent clock fingerprinting and Smurf attacks.

- Ignore bogus ICMP error responses.

- Disable source routing which allows users to redirect network traffic that
  can result in man-in-the-middle attacks.

- Do not accept IPv6 router advertisements and solicitations.

- Optional - Disable SACK and DSACK as they have historically been a known
  vector for exploitation.

- Disable TCP timestamps as they can allow detecting the system time.

- Optional - Log packets with impossible source or destination addresses to
  enable further inspection and analysis.

- Optional - Enable IPv6 Privacy Extensions.

- Documentation: https://www.kicksecure.com/wiki/Networking

### Boot parameters

Mitigations for known CPU vulnerabilities are enabled in their strictest form
and simultaneous multithreading (SMT) is disabled. See the
`/etc/default/grub.d/40_cpu_mitigations.cfg` configuration file.

Note, to achieve complete protection for known CPU vulnerabilities, the latest
security microcode (BIOS/UEFI) updates must be installed on the system. Furthermore,
if using Secure Boot, the Secure Boot Forbidden Signature Database (DBX) must be kept
up to date through [UEFI Revocation List](https://github.com/microsoft/secureboot_objects) updates.

CPU mitigations:

- Disable Simultaneous Multithreading (SMT)

- Spectre Side Channels (BTI and BHI)

- Speculative Store Bypass (SSB)

- L1 Terminal Fault (L1TF)

- Microarchitectural Data Sampling (MDS)

- TSX Asynchronous Abort (TAA)

- iTLB Multihit

- Special Register Buffer Data Sampling (SRBDS)

- L1D Flushing

- Processor MMIO Stale Data

- Arbitrary Speculative Code Execution with Return Instructions (Retbleed)

- Cross-Thread Return Address Predictions

- Speculative Return Stack Overflow (SRSO)

- Gather Data Sampling (GDS)

- Register File Data Sampling (RFDS)

- Indirect Target Selection (ITS)

- VMScape

Boot parameters relating to kernel hardening, DMA mitigations, and entropy
generation are outlined in the `/etc/default/grub.d/40_kernel_hardening.cfg`
configuration file.

Kernel space:

- Disable merging of slabs with similar size, which reduces the risk of
  triggering heap overflows and limits influencing slab cache layout.

- Enable sanity checks and red zoning via slab debugging. This will implicitly
  disable kernel pointer hashing, leaking very sensitive information to root.

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

- Optional - Modify the machine check exception handler.

- Prevent sensitive kernel information leaks in the console during boot.

- Enable the kernel Electric-Fence sampling-based memory safety error detector
  which can identify heap out-of-bounds access, use-after-free, and invalid-free errors.

- Disable 32-bit vDSO mappings as they are a legacy compatibility feature.

- Use kCFI as the default CFI implementation as it is more resilient to attacks that are
  able to write arbitrary executables into memory omitting the necessary hash validation.

- Disable support for all 32-bit x86 processes and syscalls to reduce attack surface.

- Disable the EFI persistent storage feature which prevents the kernel from writing crash logs
  and other persistent data to either the UEFI variable storage or ACPI ERST backends.

Direct memory access:

- Enable strict IOMMU translation to protect against some DMA attacks via the use
  of both CPU manufacturer-specific drivers and kernel settings.

- Clear the busmaster bit on all PCI bridges during the EFI hand-off, which disables
  DMA before the IOMMU is configured. May cause boot failure on certain hardware.

Entropy:

- Do not credit the CPU or bootloader as entropy sources at boot in order to
  maximize the absolute quantity of entropy in the combined pool.

- Obtain more entropy at boot from RAM as the runtime memory allocator is
  being initialized.

Networking:

- Optional - Disable the entire IPv6 stack to reduce attack surface.

### mmap ASLR

- The bits of entropy used for mmap ASLR for all CPU architectures are maxed
  out via `/usr/libexec/security-misc/mmap-rnd-bits` (set to the values of
  `CONFIG_ARCH_MMAP_RND_BITS_MAX` and `CONFIG_ARCH_MMAP_RND_COMPAT_BITS_MAX`
  that the kernel was built with), therefore improving its effectiveness.

### Kernel Self Protection Project (KSPP) compliance status

**Summary:**

`security-misc` is in full compliance with KSPP recommendations wherever feasible. However,
there are a few cases of partial or non-compliance due to technical limitations.

* [KSPP Recommended Settings](https://kspp.github.io/Recommended_Settings)

**Full compliance:**

More than 30 kernel boot parameters and over 30 sysctl settings are fully aligned with
the KSPP's recommendations.

**Partial compliance:**

1. `sysctl kernel.yama.ptrace_scope=3`

Completely disables `ptrace()`. Can be enabled easily if needed.

* [security-misc pull request #242](https://github.com/Kicksecure/security-misc/pull/242)

**Non-compliance:**

2. `sysctl user.max_user_namespaces=0`

Disables user namespaces entirely. Not recommended due to the potential for widespread breakages.

* [security-misc pull request #263](https://github.com/Kicksecure/security-misc/pull/263)

3. `sysctl fs.binfmt_misc.status=0`

Disables the registration of interpreters for miscellaneous binary formats. Currently not
feasible due to compatibility issues with Firefox.

* [security-misc pull request #249](https://github.com/Kicksecure/security-misc/pull/249)
* [security-misc issue #267](https://github.com/Kicksecure/security-misc/issues/267)

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

- Miscellaneous: Blacklist an assortment of other modules to prevent them from
  automatically loading.

Specific kernel modules are entirely disabled to reduce attack surface via
`/etc/modprobe.d/30_security-misc_disable.conf`. Disabling prohibits kernel
modules from starting. This approach should not be considered comprehensive;
rather, it is a form of badness enumeration. Any potential candidates for future
disabling should first be blacklisted for a suitable amount of time.

Hardware modules:

- Optional - Bluetooth: Disabled to reduce attack surface.

- FireWire (IEEE 1394): Disabled as they are often vulnerable to DMA attacks.

- GPS: Disable GPS-related modules such as those required for Global Navigation
  Satellite Systems (GNSS).

- Optional - Intel Management Engine (ME): Provides some disabling of the interface
  between the Intel ME and the OS. May lead to breakages in places such as firmware
  updates, security, power management, display, and DRM. See discussion: https://github.com/Kicksecure/security-misc/issues/239

- Intel Platform Monitoring Technology (PMT) Telemetry: Disable some functionality
  of the Intel PMT components.

- Thunderbolt: Disabled as they are often vulnerable to DMA attacks.

File system modules:

- File Systems: Disable uncommon and legacy file systems.

- Network File Systems: Disable uncommon and legacy network file systems.

Networking modules:

- Network Protocols: A wide array of uncommon and legacy network protocols and drivers
  are disabled.

Miscellaneous modules:

- Amateur Radios: Disabled to reduce attack surface.

- Optional - CPU MSRs: Disabled as can be abused to write to arbitrary memory.

- Floppy Disks: Disabled to reduce attack surface.

- Framebuffer (fbdev): Disabled as these drivers are well-known to be buggy, cause
  kernel panics, and are generally only used by legacy devices.

- Replaced Modules: Disabled legacy drivers that have been entirely replaced and
  superseded by newer drivers.

- Optional - USB Video Device Class: Disables the USB-based video streaming driver for
  devices like some webcams and digital camcorders.

- Vivid: Disabled to reduce attack surface given previous vulnerabilities.

### Other

- A systemd service clears the System.map file on boot as these contain kernel
  pointers. The file is completely overwritten with zeroes to ensure it cannot
  be recovered. See:

`/etc/kernel/postinst.d/30_remove-system-map`

`/usr/lib/systemd/system/remove-system-map.service`

`/usr/libexec/security-misc/remove-system.map`

- Coredumps are disabled as they may contain important information such as
  encryption keys or passwords. See:

`/etc/security/limits.d/30_security-misc.conf`

`/usr/lib/sysctl.d/30_security-misc.conf`

`/usr/lib/systemd/coredump.conf.d/30_security-misc.conf`

- PStore is disabled as crash logs can contain sensitive system data such as
  kernel version, hostname, and users. See:

  `/usr/lib/systemd/pstore.conf.d/30_security-misc.conf`

- An initramfs hook used to set the sysctl values in `/etc/sysctl.conf` and
  `/etc/sysctl.d` before init is executed so sysctl hardening is enabled as
  early as possible. This was implemented for `initramfs-tools` only because
  this is not needed for `dracut` as `dracut` does that by default, at
  least on `systemd` enabled systems. Not researched for non-`systemd` systems
  by the author of this part of the readme. This is no longer implemented for
  `initramfs-tools` as `initramfs-tools` support has been deprecated.

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

- **Default Behavior**: Although Bluetooth capability is 'enabled' in the kernel,
  security-misc deviates from the usual behavior by starting with Bluetooth
  turned off at system start. This setting remains until the user explicitly opts
  to activate Bluetooth.

- **User Control**: Users have the freedom to easily switch Bluetooth on and off
  in the usual way, exercising their own discretion. This can be done via the
  Bluetooth toggle through the usual way, that is either through GUI settings
  application or command line commands.

- **Enhanced Privacy Settings**: We enforce more private defaults for Bluetooth
  connections. This includes the use of private addresses and strict timeout
  settings for discoverability and visibility.

- **Security Considerations**: Despite these measures, it's important to note that
  Bluetooth technology, by its nature, may still be prone to exploits due to its
  history of security vulnerabilities. Thus, we recommend users to opt-out of
  using Bluetooth when possible.

### Configuration Details

- See configuration: `/etc/bluetooth/30_security-misc.conf`
- For more information and discussion: [GitHub Pull Request](https://github.com/Kicksecure/security-misc/pull/145)

### Understanding Bluetooth Terms

- **Disabling Bluetooth**: This means the absence of the Bluetooth kernel module.
  When disabled, Bluetooth is non-existent in the system - it cannot be seen, set,
  configured, or interacted with in any way.

- **Turning Bluetooth On/Off**: This refers to a software toggle. Normally, on
  Debian systems, Bluetooth is 'on' when the system boots up. It actively searches
  for known devices to auto-connect and may be discoverable or visible under certain
  conditions. Our default ensures that Bluetooth is off on startup. However, it
  remains 'enabled' in the kernel, meaning the kernel can use the Bluetooth protocol
  and has the necessary modules.

### Quick Toggle Guide

- **Turning Bluetooth On**: Simply click the Bluetooth button in the settings
  application or on the tray, and switch the toggle. It's a straightforward action
  that can be completed in less than a second.

- **Turning Bluetooth Off**: Follow the same procedure as turning it on but switch
  the toggle to the off position.

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

The default `umask` is set to `027` for files created by non-root users, such
as the account `user`.

This is done using the PAM module `pam_mkhomedir.so umask=027`.

This configuration ensures that files created by non-root users cannot be read
by other non-root users by default. While Permission Lockdown already protects
the `/home` folder, this setting extends protection to other folders such as
`/tmp`.

`group` read permissions are not removed. This is unnecessary due to Debian's
use of User Private Groups (UPGs). See also:
https://wiki.debian.org/UserPrivateGroups

The default `umask` is unchanged for root because configuration files created
in `/etc` by the system administrator would otherwise be unreadable by
"others," potentially breaking applications. Examples include `/etc/firefox-esr`
and `/etc/thunderbird`. Additionally, the `umask` is set to `022` via `sudoers`
configuration, ensuring that files created as root are world-readable, even
when using commands such as `sudo vi /etc/file` or `sudo -i; touch /etc/file`.

When using `sudo`, the `umask` is set to `022` rather than `027` to ensure
compatibility with commands such as `sudo vi /etc/configfile` and
`sudo -i; touch /etc/file`.

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

## Emergency shutdown

- Forcibly powers off the system if the drive the system booted from is
  removed from the system.
- Forcibly powers off the system if a user-configurable "panic key sequence"
  is pressed (Ctrl+Alt+Delete by default).
- Forcibly powers off the system if
  `sudo /run/emerg-shutdown --instant-shutdown` is called.
- Optional - Forcibly powers off the system if shutdown gets stuck for longer
  than a user-configurable number of seconds (30 by default). Requires tuning
  by the user to function properly, see notes in
  `/etc/security-misc/emerg-shutdown/30_security_misc.conf`.

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
- Security and privacy enhancements for gnupg's config file
  `/etc/skel/.gnupg/gpg.conf`. See also:
  - https://raw.github.com/ioerror/torbirdy/master/gpg.conf
  - https://github.com/ioerror/torbirdy/pull/11
- Hardens SSH client
  `/etc/ssh/ssh_config.d/30_security-misc.conf`
- Hardens SSH server
  `/etc/ssh/sshd_config.d/30_security-misc.conf`

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
