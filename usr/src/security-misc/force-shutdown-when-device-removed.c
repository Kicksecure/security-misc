/*
 * Copyright (C) 2025 - 2025 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
 * See the file COPYING for copying conditions.
 */

/*
 * This program is designed specifically to immediately and forcibly power off
 * the system in the event the device providing the root filesystem is
 * abruptly removed from the system. The idea is that a user can shut down
 * a portable installation of Kicksecure by simply yanking the USB drive
 * containing the installation from the computer. Tails provides essentially
 * the same feature, however it is known for occasionally failing to do its
 * job properly.
 *
 * The fact that we're triggering a shutdown when the device containing the
 * root filesystem vanishes presents a number of significant challenges:
 *
 * - The device providing the entire operating system is gone. The only things
 *   we will still have left are the kernel, files loaded into RAM (for
 *   instance under /run), and anything that happens to still be in the
 *   system's disk cache.
 * - Virtually any process on the system may abruptly crash at any time. This
 *   isn't just because applications may be unable to access files. The Linux
 *   kernel's virtual memory subsystem doesn't just page out RAM contents to a
 *   swap file, it will sometimes simply erase pages containing executable
 *   code from memory if it can reload that code from disk later when needed.
 *   If part of a program isn't present in memory, and then the root device
 *   vanishes, any attempt to use code in the absent part of the application
 *   will result in the application crashing. (Attempts to access data in RAM
 *   that happened to be paged out will result in a similar crash.)
 * - We have no control over what is and isn't in the disk cache, which makes
 *   it unsafe to launch any dynamically linked executable. What happens if we
 *   need to load a missing part of libc? What if the dynamic linker itself
 *   needs loaded from disk?
 * - Systemd could lock up at any time, since the init process isn't immune to
 *   having bits of it erased from RAM to free up memory. If systemd receives
 *   a SIGSEGV, rather than crashing (which would panic the kernel), it goes
 *   into an "emergency mode" that tries to keep the system as operational as
 *   possible even though PID 1 is now out of service.
 *
 * Circumventing this set of difficulties is not easy, and it might not even
 * be entirely possible. To give our feature the highest chance of success:
 *
 * - We use memlockd to lock systemd and all libraries it depends on into
 *   memory. It can holds its own pretty well in the event of a segfault, but
 *   if its crash handler ends up re-segfaulting, that could get ugly.
 * - We compile the utility at boot time, statically link it against all of
 *   its dependencies (really only one, glibc), and load it into /run. This
 *   allows for decent architecture independence while removing any dependency
 *   on anything that isn't in RAM, thus (hopefully!) making the process
 *   crash-immune.
 * - Because we're static-linking against glibc, we cannot call anything
 *   defined in stdio.h. This is because glibc uses dlopen() to load iconv
 *   modules, which are used internally by glibc for locale support. Things
 *   defined in stdio.h may use iconv, so calling anything there will
 *   basically make our static-linked executable become dynamically linked,
 *   which could segfault it since the root filesystem is gone. We can't call
 *   anything that could touch Name Service Switch (NSS) either, but we have
 *   no need to do so, so we should be safe there. See
 *   https://stackoverflow.com/questions/57476533/why-is-statically-linking-glibc-discouraged
 * - We can't use udev either because libudev is only available as a dynamic
 *   library. That means we have to listen to kernel uevents directly to
 *   determine when the root device vanishes. Thankfully this isn't as much of
 *   a pain as it might sound like.
 * - We don't call out to any external process, since those external processes
 *   could segfault.
 *
 * This is likely superior to Tails' implementation, which uses udev (and thus
 * dynamic linking), uses an interpreter-driven script to shut down the system
 * when the root device vanishes, and calls out to external executables to
 * actually shut the system down. These issues are likely why Tails'
 * implementation of emergency shutdown occasionally fails. See
 * https://www.reddit.com/r/tails/comments/xh8njn/tails_wont_shutdown_when_i_pull_usb_stick/
 * (there are other similar posts as well).
 */

#include <sys/socket.h>
#include <sys/reboot.h>
#include <unistd.h>
#include <asm/types.h>
#include <linux/netlink.h>
#include <string.h>
#include <stdbool.h>
#include <fcntl.h>
#include <stdlib.h>

#define fd_stdin 0
#define fd_stdout 1
#define fd_stderr 2

void print(int fd, char *str) {
  size_t len = strlen(str) + 1;
  while (true) {
    ssize_t write_len = write(fd, str, len);
    len -= write_len;
    if (len == 0) {
      return;
    }
    str += write_len;
  }
}

void print_usage() {
  print(fd_stderr, "Usage:\n");
  print(fd_stderr, "  force-shutdown-when-device-removed DEVICE1 [DEVICE2...]\n");
  print(fd_stderr, "Example:\n");
  print(fd_stderr, "  force-shutdown-when-device-removed /dev/sda3\n");
}

int main(int argc, char **argv) {
  if (getuid() != 0) {
    print(fd_stderr, "This program must be run as root!\n");
    exit(1);
  }

  if (argc < 2) {
    print(fd_stderr, "Invalid number of arguments!\n");
    print_usage();
    exit(1);
  }

  size_t target_dev_name_list_len = argc - 1;
  char **target_dev_name_list = calloc(target_dev_name_list_len,
    sizeof(char *));
  if (target_dev_name_list == NULL) {
    print(fd_stderr, "Out of memory during early setup!\n");
    exit(1);
  }

  for (int i = 1; i < argc; i++) {
    char *target_dev_path = argv[i];
    if (access(target_dev_path, F_OK) != 0) {
      print(fd_stderr, "One of the specified devices does not exist!\n");
      print_usage();
      exit(1);
    }

    if (strncmp(target_dev_path, "/dev/sr", strlen("/dev/sr")) != 0
      && strncmp(target_dev_path, "/dev/nvme", strlen("/dev/nvme")) != 0
      && strncmp(target_dev_path, "/dev/sd", strlen("/dev/sd")) != 0
      && strncmp(target_dev_path, "/dev/mmc", strlen("/dev/mmc")) != 0
      && strncmp(target_dev_path, "/dev/vd", strlen("/dev/vd")) != 0
      && strncmp(target_dev_path, "/dev/xvd", strlen("/dev/xvd")) != 0
      && strncmp(target_dev_path, "/dev/hd", strlen("/dev/hd")) != 0) {
      print(fd_stderr, "One of the specified devices is not supported!\n");
      print_usage();
      exit(1);
    }

    size_t device_path_slash_count = 0;
    for (size_t j = 0; j < strlen(target_dev_path); j++) {
      if (target_dev_path[j] == '/') {
        device_path_slash_count++;
      }
    }
    if (device_path_slash_count != 2) {
      print(fd_stderr, "One of the specified devices is not supported!\n");
      print_usage();
      exit(1);
    }

    char *target_dev_parse = calloc(1, strlen(target_dev_path) + 1);
    if (target_dev_parse == NULL) {
      print(fd_stderr, "Out of memory during early setup!\n");
      exit(1);
    }
    memcpy(target_dev_parse, target_dev_path, strlen(target_dev_path) + 1);

    /* returns "dev" */
    char *target_dev_name = strtok(target_dev_parse, "/");
    /* returns the actual device name we want */
    target_dev_name = strtok(NULL, "/");
    if (target_dev_name == NULL) {
      print(fd_stderr, "One of the specified devices is not supported!\n");
      print_usage();
      exit(1);
    }

    target_dev_name_list[i - 1] = calloc(1, strlen(target_dev_name) + 1);
    memcpy(target_dev_name_list[i - 1], target_dev_name,
      strlen(target_dev_name) + 1);
    free(target_dev_parse);
  }

  struct sockaddr_nl sa = {
    .nl_family = AF_NETLINK,
    .nl_pad = 0,
    .nl_pid = getpid(),
    .nl_groups = NETLINK_KOBJECT_UEVENT,
  };
  int ns = socket(AF_NETLINK, SOCK_DGRAM, NETLINK_KOBJECT_UEVENT);
  if (ns < 0) {
    print(fd_stderr, "Failed to create netlink socket!\n");
    exit(1);
  }
  int ret = bind(ns, (struct sockaddr *) &sa, sizeof(sa));
  if (ret < 0) {
    print(fd_stderr, "Failed to bind netlink socket!\n");
    exit(1);
  }

  while (true) {
    /*
     * So, you looked at `man 7 netlink`, then looked at this code, and can't
     * figure out how on earth any of this makes sense? Well guess what, turns
     * out NETLINK_KOBJECT_UEVENT messages break all of the rules about how
     * netlink messages work specified in that manpage. What you actually
     * get... well, depends.
     *
     * - The messages we actually want are just NUL-separated string lists.
     *   These are the actual kernel uevents.
     * - Mixed in with those will be uevents generated by systemd-udevd, which
     *   use a different format and are unsuitable for our purposes. We have
     *   to ignore those. Thankfully those messages start with the
     *   NUL-terminated string "libudev" so they're easy to filter out.
     */

    int len;
    char buf[16384];
    struct iovec iov = { buf, sizeof(buf) };
    struct sockaddr_nl sa2;
    struct msghdr msg = { &sa2, sizeof(sa2), &iov, 1, NULL, 0, 0 };
    len = recvmsg(ns, &msg, 0);
    if (len == -1) {
      reboot(RB_POWER_OFF);
      //print(fd_stderr, "SHUTDOWN!!!\n");
      exit(0);
    }

    if (len < 8) {
      /* There aren't any super-short messages we're interested in, discard
       * them */
      continue;
    }
    if (memcmp(buf, "libudev", 8) == 0) {
      /* udevd message, ignore */
      continue;
    }

    char *tmpbuf = buf;
    bool device_removed = false;
    while (len > 0) {
      if (strcmp(tmpbuf, "ACTION=remove") == 0) {
        device_removed = true;
        goto next_str;
      }

      if (strncmp(tmpbuf, "DEVNAME=", strlen("DEVNAME=")) == 0) {
        if (device_removed) {
          char *rem_devname_line;
          /*
           * Try to allocate the memory needed to check DEVNAME in a loop. We
           * really do not want to simply abort here due to an out of memory
           * condition, because that would result in the shutdown never
           * occurring. We also don't want to force a shutdown when memory
           * runs out, as that could result in the user losing work because
           * they opened too many browser tabs.
           */
          while(true) {
            rem_devname_line = calloc(1, strlen(tmpbuf) + 1);
            if (rem_devname_line == NULL) {
              print(fd_stderr, "Out of memory while parsing devname, retrying in one second\n");
              sleep(1);
              continue;
            } else {
              break;
            }
          }

          memcpy(rem_devname_line, tmpbuf, strlen(tmpbuf) + 1);
          /* returns DEVNAME */
          char *rem_dev_name = strtok(rem_devname_line, "=");
          /* returns the actual device name */
          rem_dev_name = strtok(NULL, "=");
          if (rem_dev_name == NULL) {
            continue;
          }

          for (int i = 0; i < target_dev_name_list_len; i++) {
            if (strcmp(rem_dev_name, target_dev_name_list[i]) == 0) {
              reboot(RB_POWER_OFF);
              //print(fd_stderr, "SHUTDOWN!!!\n");
              exit(0);
            }
          }
          free(rem_devname_line);
        }
      }

next_str:
      len -= strlen(tmpbuf) + 1;
      tmpbuf += strlen(tmpbuf) + 1;
    }
  }
}
