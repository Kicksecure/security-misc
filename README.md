# Enhances miscellaneous security settings

## Kernel hardening

This section is inspired by the Kernel Self Protection Project (KSPP). It
implements all recommended Linux kernel settings by the KSPP and many
more.

* https://kernsec.org/wiki/index.php/Kernel_Self_Protection_Project

### sysctl

sysctl settings are configured via the `/etc/sysctl.d/30_security-misc.conf`
configuration file.

*  A kernel pointer points to a specific location in kernel memory. These
can be very useful in exploiting the kernel so they are restricted to `CAP_SYSLOG`.

* The kernel logs are restricted to `CAP_SYSLOG` as they can often leak sensitive
information such as kernel pointers.

* The `ptrace()` system call is restricted to `CAP_SYS_PTRACE`.

* eBPF is restricted to `CAP_BPF` (`CAP_SYS_ADMIN` on kernel versions prior
to 5.8) and JIT hardening techniques such as constant blinding are enabled.

* Restricts performance events to `CAP_PERFMON` (`CAP_SYS_ADMIN` on kernel
versions prior to 5.8).

* Restricts loading line disciplines to `CAP_SYS_MODULE` to prevent unprivileged
attackers from loading vulnerable line disciplines with the `TIOCSETD` ioctl which
has been abused in a number of exploits before.

* Restricts the `userfaultfd()` syscall to `CAP_SYS_PTRACE` as `userfaultfd()` is
often abused to exploit use-after-free flaws.

* Kexec is disabled as it can be used to load a malicious kernel and gain
arbitrary code execution in kernel mode.

* Randomises the addresses for mmap base, heap, stack, and VDSO pages.

* Prevents unintentional writes to attacker-controlled files.

* Prevents common symlink and hardlink TOCTOU races.
<!--
* Restricts the SysRq key so it can only be used for shutdowns and the
Secure Attention Key.
-->
* Disables SysRq completely.

* The kernel is only allowed to swap if it is absolutely necessary. This
prevents writing potentially sensitive contents of memory to disk.

* TCP timestamps are disabled as it can allow detecting the system time.

* Enforces the logging of martian packets, those with a source address which is blatantly wrong.

* Set coredump file name based on core_pattern value instead of the default of naming it 'core'.

### mmap ASLR

* The bits of entropy used for mmap ASLR are maxed out via
`/usr/libexec/security-misc/mmap-rnd-bits` (set to the values of
`CONFIG_ARCH_MMAP_RND_BITS_MAX` and `CONFIG_ARCH_MMAP_RND_COMPAT_BITS_MAX` that
the kernel was built with), therefore improving its effectiveness.

### Boot parameters

Boot parameters are outlined in configuration files located in the
`etc/default/grub.d/` directory.

* Slab merging is disabled which significantly increases the difficulty of
heap exploitation by preventing overwriting objects from merged caches and
by making it harder to influence slab cache layout.

* Memory zeroing at allocation and free time is enabled to mitigate some
use-after-free vulnerabilities and erase sensitive information in memory.

* Page allocator freelist randomization is enabled.

* Kernel Page Table Isolation is enabled to mitigate Meltdown and increase
KASLR effectiveness.

* vsyscalls are disabled as they are obsolete, are at fixed addresses and thus,
are a potential target for ROP.

* The kernel panics on oopses to thwart certain kernel exploits.

* Enables randomisation of the kernel stack offset on syscall entries.

* All mitigations for known CPU vulnerabilities are enabled and SMT is
disabled.

* IOMMU is enabled to prevent DMA attacks along with strict enforcement of IOMMU
TLB invalidation so devices will never be able to access stale data contents.

* Distrust the 'randomly' generated CPU and bootloader seeds.

### Kernel Modules
#### Kernel Module Signature Verification

Not yet due to issues:

* https://forums.whonix.org/t/enforce-kernel-module-software-signature-verification-module-signing-disallow-kernel-module-loading-by-default/7880/64
* https://github.com/dell/dkms/issues/359

See:

* `/etc/default/grub.d/40_only_allow_signed_modules.cfg`

#### Disables the loading of new modules to the kernel after the fact

Not yet due to issues:

* https://github.com/Kicksecure/security-misc/pull/152

A systemd service dynamically sets the kernel parameter ```modules_disabled``` to 1, preventing new modules from being loaded. Since this isn't configured directly within systemctl, it does not break the loading of legitimate and necessary modules for the user, like drivers etc., given they are plugged in on startup.

#### Disables and blacklists kernel modules

Certain kernel modules are disabled and blacklisted by default to reduce attack surface via the
`/etc/modprobe.d/30_security-misc.conf` configuration file.

* Deactivates Netfilter's connection tracking helper - this module
increases kernel attack surface by enabling superfluous functionality
such as IRC parsing in the kernel. Hence, this feature is disabled.

* Thunderbolt and numerous FireWire kernel modules are also disabled as they are
often vulnerable to DMA attacks.

* The MSR kernel module is disabled to prevent CPU MSRs from being
abused to write to arbitrary memory.

* Uncommon network protocols are blacklisted. This includes:

 DCCP - Datagram Congestion Control Protocol

 SCTP - Stream Control Transmission Protocol

 RDS - Reliable Datagram Sockets

 TIPC - Transparent Inter-process Communication

 HDLC - High-Level Data Link Control

 AX25 - Amateur X.25

 NetRom

 X25

 ROSE

 DECnet

 Econet

 af_802154 - IEEE 802.15.4

 IPX - Internetwork Packet Exchange

 AppleTalk

 PSNAP - Subnetwork Access Protocol

 p8023 - Novell raw IEEE 802.3

 p8022 - IEEE 802.2

 CAN - Controller Area Network

 ATM

* Disables a large array of uncommon file systems and network file systems that reduces the attack surface especially against legacy approaches.

* The vivid kernel module is only required for testing and has been the cause
of multiple vulnerabilities so it is disabled.

* Provides some disabling of the interface between the [Intel Management Engine (ME)](https://www.kernel.org/doc/html/latest/driver-api/mei/mei.html) and the OS.

* Incorporates much of [Ubuntu's](https://git.launchpad.net/ubuntu/+source/kmod/tree/debian/modprobe.d?h=ubuntu/disco) default blacklist of modules to be blocked from automatically loading. However, they are  still permitted to load.

* Blocks automatic loading of the modules needed to use of CD-ROM devices by default. Not completely disabled yet.

### Other

* A systemd service clears the System.map file on boot as these contain kernel
pointers. The file is completely overwritten with zeroes to ensure it cannot
be recovered. See:

`/etc/kernel/postinst.d/30_remove-system-map`

`/lib/systemd/system/remove-system-map.service`

`/usr/libexec/security-misc/remove-system.map`

* Coredumps are disabled as they may contain important information such as
encryption keys or passwords. See:

`/etc/security/limits.d/30_security-misc.conf`

`/etc/sysctl.d/30_security-misc.conf`

`/lib/systemd/coredump.conf.d/30_security-misc.conf`

* An initramfs hook sets the sysctl values in `/etc/sysctl.conf` and
`/etc/sysctl.d` before init is executed so sysctl hardening is enabled
as early as possible. This is implemented for `initramfs-tools` only because
this is not needed for `dracut` because `dracut` does that by default, at least
on `systemd` enabled systems. Not researched for non-`systemd` systems by the
author of this part of the readme.

## Network hardening

* TCP syncookies are enabled to prevent SYN flood attacks.

* ICMP redirect acceptance, ICMP redirect sending, source routing and
IPv6 router advertisements are disabled to prevent man-in-the-middle attacks.

* The kernel is configured to ignore all ICMP requests to avoid Smurf attacks,
make the device more difficult to enumerate on the network and prevent clock
fingerprinting through ICMP timestamps.

* RFC1337 is enabled to protect against time-wait assassination attacks by
dropping RST packets for sockets in the time-wait state.

* Reverse path filtering is enabled to prevent IP spoofing and mitigate
vulnerabilities such as CVE-2019-14899.

* Unlike version 4, IPv6 addresses can provide information not only about the originating network, but also the originating device.
  We prevent this from happening by enabling the respective privacy extensions for IPv6.

* In addition, we deny the capability to track the originating device in the network at all, by using randomized MAC addresses per connection per default.

See:

* `/usr/lib/NetworkManager/conf.d/80_ipv6-privacy.conf`
* `/usr/lib/NetworkManager/conf.d/80_randomize-mac.conf`
* `/usr/lib/systemd/networkd.conf.d/80_ipv6-privacy-extensions.conf`

## Network & Bluetooth hardening

* Bluetooth is left enabled but users are highly discouraged from ever turning it on, due to its history of numerous security vulnerabilities. Unlike the default settings, we start the system with bluetooth turned off. We also enforce private addresses and strict timeout settings for discoverability and visibility.

See:

* `/etc/bluetooth/30_security-misc.conf`
* https://github.com/Kicksecure/security-misc/pull/145

## Entropy collection improvements

* The `jitterentropy_rng` kernel module is loaded as early as possible
during boot to gather more entropy via the
`/usr/lib/modules-load.d/30_security-misc.conf` configuration file.

* Distrusts the CPU for initial entropy at boot as it is not possible to
audit, may contain weaknesses or a backdoor. For references, see:
`/etc/default/grub.d/40_distrust_cpu.cfg`

* Gathers more entropy during boot if using the linux-hardened kernel patch.

## Restrictive mount options

A systemd service is triggered on boot to remount all sensitive partitions and directories with significantly more secure hardened mount options.
Since this would require manual tuning for a given specific system, we handle it by creating a very solid configuration file for that very system on package install.

Not enabled by default yet. In development. Help welcome.

* https://github.com/Kicksecure/security-misc/pull/152
* https://forums.whonix.org/t/re-mount-home-and-other-with-noexec-and-nosuid-among-other-useful-mount-options-for-better-security/

## Root access restrictions

* `su` is restricted to only users within the group `sudo` which prevents
users from using `su` to gain root access or to switch user accounts -
`/usr/share/pam-configs/wheel-security-misc`
(which results in a change in file `/etc/pam.d/common-auth`).

* Add user `root` to group `sudo`. This is required due to the above restriction so
that logging in from a virtual console is still possible - `debian/security-misc.postinst`

* Abort login for users with locked passwords -
`/usr/libexec/security-misc/pam-abort-on-locked-password`.

* Logging into the root account from a virtual, serial, whatnot console is
prevented by shipping an existing and empty `/etc/securetty` file
(deletion of `/etc/securetty` has a different effect).

This package does not yet automatically lock the root account password. It
is not clear if this would be sane in such a package although, it is recommended
to lock and expire the root account.

In new Kicksecure builds, root account will be locked by package
dist-base-files.

See:

* https://www.kicksecure.com/wiki/Root
* https://www.kicksecure.com/wiki/Dev/Permissions
* https://forums.whonix.org/t/restrict-root-access/7658

However, a locked root password will break rescue and emergency shell.
Therefore, this package enables passwordless rescue and emergency shell.
This is the same solution that Debian will likely adapt for Debian
installer: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=802211

See:

* `/etc/systemd/system/emergency.service.d/override.conf`
* `/etc/systemd/system/rescue.service.d/override.conf`

Adverse security effects can be prevented by setting up BIOS password
protection, GRUB password protection and/or full disk encryption.

## Console lockdown

This uses pam_access to allow members of group `console` to use console but
restrict everyone else (except members of group `console-unrestricted`) from
using console with ancient, unpopular login methods such as `/bin/login`
over networks as this might be exploitable. (CVE-2001-0797)

This is not enabled by default in this package since this package does not
know which users shall be added to group 'console' and thus, would break console.

See:

* `/usr/share/pam-configs/console-lockdown-security-misc`
* `/etc/security/access-security-misc.conf`

## Brute force attack protection

User accounts are locked after 50 failed login attempts using `pam_faillock`.

Informational output during Linux PAM:

* Show failed and remaining password attempts.
* Document unlock procedure if Linux user account got locked.
* Point out that there is no password feedback for `su`.
* Explain locked root account if locked.

See:

* `/usr/share/pam-configs/tally2-security-misc`
* `/usr/libexec/security-misc/pam-info`
* `/usr/libexec/security-misc/pam-abort-on-locked-password`

## Access rights restrictions

### Strong user account separation

#### Permission Lockdown

Read, write and execute access for "others" are removed during package
installation, upgrade or PAM `mkhomedir` for all users who have home
folders in `/home` by running, for example:

```
chmod o-rwx /home/user
```

This will be done only once per folder in `/home` so users who wish to
relax file permissions are free to do so. This is to protect files in a
home folder that were previously created with lax file permissions prior
to the installation of this package.

See:

* `debian/security-misc.postinst`
* `/usr/libexec/security-misc/permission-lockdown`
* `/usr/share/pam-configs/mkhomedir-security-misc`

#### umask

Default `umask` is set to `027` for files created by non-root users
such as for example user `user`.

This is doing using pam module `pam_mkhomedir.so umask=027`.

This means, files created by non-root users cannot be read by other
non-root users by default. While Permission Lockdown already protects
the `/home` folder, this protects other folders such as `/tmp`.

`group` read permissions are not removed.
This is unnecessary due to Debian's use of User Private Groups (UPGs).
See also: https://wiki.debian.org/UserPrivateGroups

Default `umask` is unchanged for root, because then configuration files
created in `/etc` by the system administrator would be unreadable by
"others" and break applications. Examples include `/etc/firefox-esr` and
`/etc/thunderbird`.

See:

* `/usr/share/pam-configs/umask-security-misc`

### SUID / SGID removal and permission hardening

#### SUID / SGID removal

A systemd service removes SUID / SGID bits from non-essential binaries as
these are often used in privilege escalation attacks.

#### File permission hardening

Various file permissions are reset with more secure and hardened defaults. These include but are not limited to:

* Limiting ```/home``` and ```/root``` to the root only.
* Limiting crontab to root as well as all the configuration files for cron.
* Limiting the configuration for cups and ssh.
* Protecting the information of sudoers from others.
* Protecting various system relevant files and modules.

<!--
Not enabled by default yet.

A systemd service removes SUID / SGID bits from non-essential binaries as
these are often used in privilege escalation attacks. It is disabled by
default for now during testing and can optionally be enabled by running
`systemctl enable permission-hardening.service` as root.

See:

* `/usr/libexec/security-misc/permission-hardening`
* `/lib/systemd/system/permission-hardening.service`
* `/etc/permission-hardening.d`
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
-->
## Application-specific hardening

* Enables "`apt-get --error-on=any`" which makes apt exit non-zero for
 transient failures. - `/etc/apt/apt.conf.d/40error-on-any`.
* Enables APT seccomp-BPF sandboxing - `/etc/apt/apt.conf.d/40sandbox`.
* Deactivates previews in Dolphin.
* Deactivates previews in Nautilus -
`/usr/share/glib-2.0/schemas/30_security-misc.gschema.override`.
* Deactivates thumbnails in Thunar.
* Thunderbird is hardened with the following options:
    * Displays domain names in punycode to prevent IDN homograph attacks (a form of phishing).
    * Strips email client information for sent email headers.
    * Stripts user time information from sent email headers by replacing the originating time zone with UTC and rounding the timestamp to the nearest minute.
    * Disables scripting when viewing pdf files.
    * Disables implicit outgoing connections.
    * Disables all and any kind of telemetry.
* Security and privacy enhancements for gnupg's config file
`/etc/skel/.gnupg/gpg.conf`. See also:
    * https://raw.github.com/ioerror/torbirdy/master/gpg.conf
    * https://github.com/ioerror/torbirdy/pull/11

### project scope of application-specific hardening

Before sending pull requests to harden arbitrary applications, please note the scope of security-misc is limited to default installed applications in Kicksecure, Whonix. This includes:

* Thunderbird, VLC Media Player, KeepassXC
* Debian Specific System Components (APT, DPKG)
* System Services (NetworkManager IPv6 privacy options, MAC address randomization)
* Actually used development utilities such as `git`.

It will not be possible to review and merge "1500" settings profiles for arbitrary applications outside of this context.

Discussion:
https://github.com/Kicksecure/security-misc/issues/154

## Opt-in hardening

Some hardening is opt-in as it causes too much breakage to be enabled by
default.

* An optional systemd service mounts `/proc` with `hidepid=2` at boot to
prevent users from seeing another user's processes. This is disabled by
default because it is incompatible with `pkexec`. It can be enabled by
executing `systemctl enable proc-hidepid.service` as root.

* A systemd service restricts `/proc/cpuinfo`, `/proc/bus`, `/proc/scsi` and
`/sys` to the root user. This hides a lot of hardware identifiers from
unprivileged users and increases security as `/sys` exposes a lot of
information that shouldn't be accessible to unprivileged users. As this will
break many things, it is disabled by default and can optionally be enabled by
executing `systemctl enable hide-hardware-info.service` as root.

## miscellaneous

* hardened malloc compatibility for haveged workaround
`/lib/systemd/system/haveged.service.d/30_security-misc.conf`

* set `dracut` `reproducible=yes` setting

## Related

* Linux Kernel Runtime Guard (LKRG)
* tirdad - TCP ISN CPU Information Leak Protection.
* Kicksecure (TM) - a security-hardened Linux Distribution
* And more.
* https://www.kicksecure.com/wiki/Linux_Kernel_Runtime_Guard_LKRG
* https://github.com/Kicksecure/tirdad
* https://www.kicksecure.com
* https://github.com/Kicksecure

## Discussion

Happening primarily in forums.

https://forums.whonix.org/t/kernel-hardening/7296

## How to install `security-misc`

See https://www.kicksecure.com/wiki/Security-misc#install

## How to Build deb Package from Source Code

Can be build using standard Debian package build tools such as:

```
dpkg-buildpackage -b
```

See instructions. (Replace `generic-package` with the actual name of this package `security-misc`.)

* **A)** [easy](https://www.kicksecure.com/wiki/Dev/Build_Documentation/generic-package/easy), _OR_
* **B)** [including verifying software signatures](https://www.kicksecure.com/wiki/Dev/Build_Documentation/generic-package)

## Contact

* [Free Forum Support](https://forums.kicksecure.com)
* [Professional Support](https://www.kicksecure.com/wiki/Professional_Support)

## Donate

`security-misc` requires [donations](https://www.kicksecure.com/wiki/Donate) to stay alive!
