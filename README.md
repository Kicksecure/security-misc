# enhances misc security settings #

The following settings are changed:

deactivates previews in Dolphin;
deactivates previews in Nautilus;
deactivates thumbnails in Thunar;
deactivates TCP timestamps;
deactivates Netfilter's connection tracking helper;

TCP time stamps (RFC 1323) allow for tracking clock
information with millisecond resolution. This may or may not allow an
attacker to learn information about the system clock at such
a resolution, depending on various issues such as network lag.
This information is available to anyone who monitors the network
somewhere between the attacked system and the destination server.
It may allow an attacker to find out how long a given
system has been running, and to distinguish several
systems running behind NAT and using the same IP address. It might
also allow one to look for clocks that match an expected value to find the
public IP used by a user.

Hence, this package disables this feature by shipping the
/etc/sysctl.d/tcp_timestamps.conf configuration file.

Note that TCP time stamps normally have some usefulness. They are
needed for:

* the TCP protection against wrapped sequence numbers; however, to
trigger a wrap, one needs to send roughly 2^32 packets in one
minute:  as said in RFC 1700, "The current recommended default
time to live (TTL) for the Internet Protocol (IP) [45,105] is 64".
So, this probably won't be a practical problem in the context
of Anonymity Distributions.

* "Round-Trip Time Measurement", which is only useful when the user
manages to saturate their connection. When using Anonymity Distributions,
probably the limiting factor for transmission speed is rarely the capacity
of the user connection.

Netfilter's connection tracking helper module increases kernel attack
surface by enabling superfluous functionality such as IRC parsing in
the kernel. (!)

Hence, this package disables this feature by shipping the
/etc/sysctl.d/nf_conntrack_helper.conf configuration file.

Kernel symbols in /proc/kallsyms are hidden to prevent malware from
reading them and using them to learn more about what to attack on your system.

Kexec is disabled as it can be used for live patching of the running kernel.

The BPF JIT compiler is restricted to the root user and is hardened.

ASLR effectiveness for mmap is increased.

The ptrace system call is restricted to the root user only.

The TCP/IP stack is hardened.

This package makes some data spoofing attacks harder.

SACK is disabled as it is commonly exploited and is rarely used.

This package disables the merging of slabs of similar sizes to prevent an
attacker from exploiting them.

Sanity checks, redzoning, and memory poisoning are enabled.

The kernel now panics on uncorrectable errors in ECC memory which could
be exploited.

Kernel Page Table Isolation is enabled to mitigate Meltdown and increase
KASLR effectiveness.

SMT is disabled as it can be used to exploit the MDS vulnerability.

All mitigations for the MDS vulnerability are enabled.

DCCP, SCTP, TIPC and RDS are blacklisted as they are rarely used and may have
unknown vulnerabilities.
## How to install `security-misc` using apt-get ##

1\. Add [Whonix's Signing Key](https://www.whonix.org/wiki/Whonix_Signing_Key).

```
sudo apt-key --keyring /etc/apt/trusted.gpg.d/whonix.gpg adv --keyserver hkp://ipv4.pool.sks-keyservers.net:80 --recv-keys 916B8D99C38EAF5E8ADC7A2A8D66066A2EEACCDA
```

3\. Add Whonix's APT repository.

```
echo "deb http://deb.whonix.org buster main contrib non-free" | sudo tee /etc/apt/sources.list.d/whonix.list
```

4\. Update your package lists.

```
sudo apt-get update
```

5\. Install `security-misc`.

```
sudo apt-get install security-misc
```

## How to Build deb Package ##

Replace `apparmor-profile-torbrowser` with the actual name of this package with `security-misc` and see [instructions](https://www.whonix.org/wiki/Dev/Build_Documentation/apparmor-profile-torbrowser).

## Contact ##

* [Free Forum Support](https://forums.whonix.org)
* [Professional Support](https://www.whonix.org/wiki/Professional_Support)

## Donate ##

`security-misc` requires [donations](https://www.whonix.org/wiki/Donate) to stay alive!
