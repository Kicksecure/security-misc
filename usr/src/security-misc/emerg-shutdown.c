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

/*
 * TODO: Consider handling signals more gracefully (perhaps use ppoll instead
 * of poll, handle things like EINTR, etc.). Right now the plan is to simply
 * terminate when a signal is received and let systemd restart the process,
 * but it might be better to just be signal-resilient.
 */

#include <sys/socket.h>
#include <linux/reboot.h>
#include <unistd.h>
#include <asm/types.h>
#include <linux/netlink.h>
#include <string.h>
#include <stdbool.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <poll.h>
#include <linux/input.h>
#include <sys/syscall.h>

#define fd_stdin 0
#define fd_stdout 1
#define fd_stderr 2

#define max_inputs 255
#define input_path_size 20
#define key_flags_len 12

/* Adapted from kloak/src/keycodes.c */
struct name_value {
    const char *name;
    const int value;
};
static struct name_value key_table[] = {
        {"KEY_ESC", KEY_ESC},
        {"KEY_1", KEY_1},
        {"KEY_2", KEY_2},
        {"KEY_3", KEY_3},
        {"KEY_4", KEY_4},
        {"KEY_5", KEY_5},
        {"KEY_6", KEY_6},
        {"KEY_7", KEY_7},
        {"KEY_8", KEY_8},
        {"KEY_9", KEY_9},
        {"KEY_0", KEY_0},
        {"KEY_MINUS", KEY_MINUS},
        {"KEY_EQUAL", KEY_EQUAL},
        {"KEY_BACKSPACE", KEY_BACKSPACE},
        {"KEY_TAB", KEY_TAB},
        {"KEY_Q", KEY_Q},
        {"KEY_W", KEY_W},
        {"KEY_E", KEY_E},
        {"KEY_R", KEY_R},
        {"KEY_T", KEY_T},
        {"KEY_Y", KEY_Y},
        {"KEY_U", KEY_U},
        {"KEY_I", KEY_I},
        {"KEY_O", KEY_O},
        {"KEY_P", KEY_P},
        {"KEY_LEFTBRACE", KEY_LEFTBRACE},
        {"KEY_RIGHTBRACE", KEY_RIGHTBRACE},
        {"KEY_ENTER", KEY_ENTER},
        {"KEY_LEFTCTRL", KEY_LEFTCTRL},
        {"KEY_A", KEY_A},
        {"KEY_S", KEY_S},
        {"KEY_D", KEY_D},
        {"KEY_F", KEY_F},
        {"KEY_G", KEY_G},
        {"KEY_H", KEY_H},
        {"KEY_J", KEY_J},
        {"KEY_K", KEY_K},
        {"KEY_L", KEY_L},
        {"KEY_SEMICOLON", KEY_SEMICOLON},
        {"KEY_APOSTROPHE", KEY_APOSTROPHE},
        {"KEY_GRAVE", KEY_GRAVE},
        {"KEY_LEFTSHIFT", KEY_LEFTSHIFT},
        {"KEY_BACKSLASH", KEY_BACKSLASH},
        {"KEY_Z", KEY_Z},
        {"KEY_X", KEY_X},
        {"KEY_C", KEY_C},
        {"KEY_V", KEY_V},
        {"KEY_B", KEY_B},
        {"KEY_N", KEY_N},
        {"KEY_M", KEY_M},
        {"KEY_COMMA", KEY_COMMA},
        {"KEY_DOT", KEY_DOT},
        {"KEY_SLASH", KEY_SLASH},
        {"KEY_RIGHTSHIFT", KEY_RIGHTSHIFT},
        {"KEY_KPASTERISK", KEY_KPASTERISK},
        {"KEY_LEFTALT", KEY_LEFTALT},
        {"KEY_SPACE", KEY_SPACE},
        {"KEY_CAPSLOCK", KEY_CAPSLOCK},
        {"KEY_F1", KEY_F1},
        {"KEY_F2", KEY_F2},
        {"KEY_F3", KEY_F3},
        {"KEY_F4", KEY_F4},
        {"KEY_F5", KEY_F5},
        {"KEY_F6", KEY_F6},
        {"KEY_F7", KEY_F7},
        {"KEY_F8", KEY_F8},
        {"KEY_F9", KEY_F9},
        {"KEY_F10", KEY_F10},
        {"KEY_NUMLOCK", KEY_NUMLOCK},
        {"KEY_SCROLLLOCK", KEY_SCROLLLOCK},
        {"KEY_KP7", KEY_KP7},
        {"KEY_KP8", KEY_KP8},
        {"KEY_KP9", KEY_KP9},
        {"KEY_KPMINUS", KEY_KPMINUS},
        {"KEY_KP4", KEY_KP4},
        {"KEY_KP5", KEY_KP5},
        {"KEY_KP6", KEY_KP6},
        {"KEY_KPPLUS", KEY_KPPLUS},
        {"KEY_KP1", KEY_KP1},
        {"KEY_KP2", KEY_KP2},
        {"KEY_KP3", KEY_KP3},
        {"KEY_KP0", KEY_KP0},
        {"KEY_KPDOT", KEY_KPDOT},
        {"KEY_ZENKAKUHANKAKU", KEY_ZENKAKUHANKAKU},
        {"KEY_102ND", KEY_102ND},
        {"KEY_F11", KEY_F11},
        {"KEY_F12", KEY_F12},
        {"KEY_RO", KEY_RO},
        {"KEY_KATAKANA", KEY_KATAKANA},
        {"KEY_HIRAGANA", KEY_HIRAGANA},
        {"KEY_HENKAN", KEY_HENKAN},
        {"KEY_KATAKANAHIRAGANA", KEY_KATAKANAHIRAGANA},
        {"KEY_MUHENKAN", KEY_MUHENKAN},
        {"KEY_KPJPCOMMA", KEY_KPJPCOMMA},
        {"KEY_KPENTER", KEY_KPENTER},
        {"KEY_RIGHTCTRL", KEY_RIGHTCTRL},
        {"KEY_KPSLASH", KEY_KPSLASH},
        {"KEY_SYSRQ", KEY_SYSRQ},
        {"KEY_RIGHTALT", KEY_RIGHTALT},
        {"KEY_LINEFEED", KEY_LINEFEED},
        {"KEY_HOME", KEY_HOME},
        {"KEY_UP", KEY_UP},
        {"KEY_PAGEUP", KEY_PAGEUP},
        {"KEY_LEFT", KEY_LEFT},
        {"KEY_RIGHT", KEY_RIGHT},
        {"KEY_END", KEY_END},
        {"KEY_DOWN", KEY_DOWN},
        {"KEY_PAGEDOWN", KEY_PAGEDOWN},
        {"KEY_INSERT", KEY_INSERT},
        {"KEY_DELETE", KEY_DELETE},
        {"KEY_MACRO", KEY_MACRO},
        {"KEY_MUTE", KEY_MUTE},
        {"KEY_VOLUMEDOWN", KEY_VOLUMEDOWN},
        {"KEY_VOLUMEUP", KEY_VOLUMEUP},
        {"KEY_POWER", KEY_POWER},
        {"KEY_POWER2", KEY_POWER2},
        {"KEY_KPEQUAL", KEY_KPEQUAL},
        {"KEY_KPPLUSMINUS", KEY_KPPLUSMINUS},
        {"KEY_PAUSE", KEY_PAUSE},
        {"KEY_SCALE", KEY_SCALE},
        {"KEY_KPCOMMA", KEY_KPCOMMA},
        {"KEY_HANGEUL", KEY_HANGEUL},
        {"KEY_HANGUEL", KEY_HANGUEL},
        {"KEY_HANJA", KEY_HANJA},
        {"KEY_YEN", KEY_YEN},
        {"KEY_LEFTMETA", KEY_LEFTMETA},
        {"KEY_RIGHTMETA", KEY_RIGHTMETA},
        {"KEY_COMPOSE", KEY_COMPOSE},
        {"KEY_F13", KEY_F13},
        {"KEY_F14", KEY_F14},
        {"KEY_F15", KEY_F15},
        {"KEY_F16", KEY_F16},
        {"KEY_F17", KEY_F17},
        {"KEY_F18", KEY_F18},
        {"KEY_F19", KEY_F19},
        {"KEY_F20", KEY_F20},
        {"KEY_F21", KEY_F21},
        {"KEY_F22", KEY_F22},
        {"KEY_F23", KEY_F23},
        {"KEY_F24", KEY_F24},
        {"KEY_UNKNOWN", KEY_UNKNOWN},
        {NULL, 0}
};
int lookup_keycode(const char *name) {
  struct name_value *p;
  for (p = key_table; p->name != NULL; ++p) {
    if (strcmp(p->name, name) == 0) {
      return p->value;
    }
  }
  return -1;
}

/* Adapted from systemd/src/login/logind-button.c */
bool bitset_get(const uint64_t *bits, uint32_t i) {
  return (bits[i / 64] >> (i % 64)) & 1UL;
}

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
  print(fd_stderr, "  emerg-shutdown --devices=DEVICE1[,DEVICE2...] --keys=KEY_1[,KEY_2|KEY_3...]\n");
  print(fd_stderr, "Example:\n");
  print(fd_stderr, "  emerg-shutdown --devices=/dev/sda3 --keys=KEY_POWER\n");
}

void *safe_calloc(size_t nmemb, size_t size) {
  void *ret_buf = calloc(nmemb, size);
  if (ret_buf == NULL) {
    print(fd_stderr, "Out of memory!\n");
    exit(1);
  }
  return ret_buf;
}

void *safe_reallocarray(void *ptr, size_t nmemb, size_t size) {
  void *ret_buf = reallocarray(ptr, nmemb, size);
  if (ret_buf == NULL) {
    print(fd_stderr, "Out of memory!\n");
    exit(1);
  }
  return ret_buf;
}

/* Inspired by https://www.strudel.org.uk/itoa/ */
char *int_to_str(uint32_t val) {
  static char buf[11];
  int8_t i;
  char *rslt = NULL;
  const char *digits = "0123456789";

  buf[10] = '\0';

  for (i = 9; i >= 0; i--) {
    buf[i] = digits[val % 10];
    val /= 10;
    if (val == 0) {
      break;
    }
  }

  rslt = safe_calloc(1, 11 - i);
  memcpy(rslt, buf + i, 11 - i);
  return rslt;
}

void load_list(const char *arg, size_t *result_list_len_ref, char ***result_list_ref, const char *sep, bool parse_opt) {
  char **result_list = NULL;
  size_t result_list_len = 0;
  int arg_copy_len = strlen(arg) + 1;
  char *arg_copy = safe_calloc(1, arg_copy_len);
  char *arg_val;
  char *arg_part;

  memcpy(arg_copy, arg, arg_copy_len);
  if (parse_opt) {
    /* returns "--whatever" */
    arg_val = strtok(arg_copy, "=");
    /* returns everything after the = sign */
    arg_val = strtok(NULL, "");
  } else {
    arg_val = arg_copy;
  }

  arg_part = strtok(arg_val, sep);
  if (arg_part == NULL) {
    return;
  }

  do {
    result_list_len++;
    result_list = safe_reallocarray(result_list, result_list_len, sizeof(char *));
    result_list[result_list_len - 1] = safe_calloc(1, strlen(arg_part) + 1);
    strcpy(result_list[result_list_len - 1], arg_part);
  } while ((arg_part = strtok(NULL, ",")) != NULL);

  *result_list_len_ref = result_list_len;
  *result_list_ref = result_list;
  free(arg_copy);
}

int kill_system() {
  return syscall(SYS_reboot, LINUX_REBOOT_MAGIC1, LINUX_REBOOT_MAGIC2, LINUX_REBOOT_CMD_POWER_OFF, NULL);
}

int main(int argc, char **argv) {
  /* Working variables */
  size_t target_dev_list_len = 0;
  char **target_dev_name_raw_list = NULL;
  size_t panic_key_list_len = 0;
  char **panic_key_str_list = NULL;
  char **target_dev_list = NULL;
  int **panic_key_list = NULL;
  bool *panic_key_active_list = NULL;
  size_t event_fd_list_len = 0;
  int *event_fd_list = NULL;
  char input_path_buf[input_path_size];
  struct pollfd *pollfd_list = NULL;
  struct input_event ie_buf[64];

  /* Index variables */
  int arg_idx = 0;
  size_t tdl_idx = 0;
  size_t tdp_char_idx = 0;
  size_t pkl_idx = 0;
  int input_idx = 0;
  size_t efl_idx = 0;
  int ie_idx = 0;
  size_t kg_idx = 0;

  /* Prerequisite check */
  if (getuid() != 0) {
    print(fd_stderr, "This program must be run as root!\n");
    exit(1);
  }

  /* Argument parsing */
  if (argc < 2) {
    print(fd_stderr, "Invalid number of arguments!\n");
    print_usage();
    exit(1);
  }

  for (arg_idx = 1; arg_idx < argc; arg_idx++) {
    if (strncmp(argv[arg_idx], "--devices=", strlen("--devices=")) == 0) {
      if (target_dev_name_raw_list != NULL) {
        print(fd_stderr, "--devices cannot be passed more than once!\n");
        print_usage();
        exit(1);
      }
      load_list(argv[arg_idx], &target_dev_list_len, &target_dev_name_raw_list, ",", true);
    } else if (strncmp(argv[arg_idx], "--keys=", strlen("--keys=")) == 0) {
      if (panic_key_str_list != NULL) {
        print(fd_stderr, "--keys cannot be passed more than once!\n");
        print_usage();
        exit(1);
      }
      load_list(argv[arg_idx], &panic_key_list_len, &panic_key_str_list, ",", true);
    }
  }

  target_dev_list = safe_calloc(target_dev_list_len, sizeof(char *));
  panic_key_list = safe_calloc(panic_key_list_len, sizeof(int *));
  panic_key_active_list = safe_calloc(panic_key_list_len, sizeof(bool));

  for (tdl_idx = 0; tdl_idx < target_dev_list_len; tdl_idx++) {
    char *target_dev_path = target_dev_name_raw_list[tdl_idx];
    size_t device_path_slash_count = 0;
    char *target_dev_parse = safe_calloc(1, strlen(target_dev_path) + 1);
    char *target_dev_name = NULL;

    if (access(target_dev_path, F_OK) != 0) {
      print(fd_stderr, "The device '");
      print(fd_stderr, target_dev_path);
      print(fd_stderr, "' does not exist!\n");
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
      print(fd_stderr, "The device '");
      print(fd_stderr, target_dev_path);
      print(fd_stderr, "' is not supported!\n");
      print_usage();
      exit(1);
    }

    for (tdp_char_idx = 0; tdp_char_idx < strlen(target_dev_path); tdp_char_idx++) {
      if (target_dev_path[tdp_char_idx] == '/') {
        device_path_slash_count++;
      }
    }
    if (device_path_slash_count != 2) {
      print(fd_stderr, "The device '");
      print(fd_stderr, target_dev_path);
      print(fd_stderr, "' is not supported!\n");
      print_usage();
      exit(1);
    }

    memcpy(target_dev_parse, target_dev_path, strlen(target_dev_path) + 1);

    /* returns "dev" */
    target_dev_name = strtok(target_dev_parse, "/");
    /* returns the actual device name we want */
    target_dev_name = strtok(NULL, "/");
    if (target_dev_name == NULL) {
      print(fd_stderr, "The device '");
      print(fd_stderr, target_dev_path);
      print(fd_stderr, "' is not supported!\n");
      print_usage();
      exit(1);
    }

    target_dev_list[tdl_idx] = calloc(1, strlen(target_dev_name) + 1);
    memcpy(target_dev_list[tdl_idx], target_dev_name, strlen(target_dev_name) + 1);
    free(target_dev_parse);
  }

  for (pkl_idx = 0; pkl_idx < panic_key_list_len; pkl_idx++) {
    size_t keygroup_str_list_len = 0;
    char **keygroup_str_list = NULL;
    load_list(panic_key_str_list[pkl_idx], &keygroup_str_list_len, &keygroup_str_list, "|", false);
    int *pkl_element = safe_calloc(keygroup_str_list_len + 1, sizeof(int));

    pkl_element[keygroup_str_list_len] = 0;
    for (kg_idx = 0; kg_idx < keygroup_str_list_len; kg_idx++) {
      int keycode = lookup_keycode(keygroup_str_list[kg_idx]);
      if (keycode < 0) {
        print(fd_stderr, "Invalid key code '");
        print(fd_stderr, keygroup_str_list[kg_idx]);
        print(fd_stderr, "'!\n");
        print_usage();
        exit(1);
      }
      pkl_element[kg_idx] = keycode;
      free(keygroup_str_list[kg_idx]);
    }

    free(keygroup_str_list);
    panic_key_list[pkl_idx] = pkl_element;
  }

  /* Device event listener setup */
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

  /* Keyboard event listener setup
   * Heavily inspired by systemd/src/login/logind-button.c and
   * kloak/src/main.c */
  for (input_idx = 0; input_idx <= max_inputs; input_idx++) {
    int tmp_fd = 0;
    uint64_t key_flags[key_flags_len];
    bool supports_panic = true;
    char *loop_str = NULL;

    strcpy(input_path_buf, "/dev/input/event");
    loop_str = int_to_str(input_idx);
    strcat(input_path_buf, loop_str);
    free(loop_str);

    tmp_fd = open(input_path_buf, O_RDONLY | O_CLOEXEC | O_NOCTTY | O_NONBLOCK);
    if (tmp_fd < 0) {
      continue;
    }

    if (ioctl(tmp_fd, EVIOCGBIT(EV_SYN, sizeof(key_flags)), key_flags) < 0) {
      print(fd_stderr, "Failed to query properties of input device '");
      print(fd_stderr, input_path_buf);
      print(fd_stderr, "'!\n");
      exit(1);
    }

    if (!bitset_get(key_flags, EV_KEY)) {
      continue;
    }

    if (ioctl(tmp_fd, EVIOCGBIT(EV_KEY, sizeof(key_flags)), key_flags) < 0) {
      print(fd_stderr, "Failed to query keys available on input device '");
      print(fd_stderr, input_path_buf);
      print(fd_stderr, "'!\n");
      exit(1);
    }

    for (pkl_idx = 0; pkl_idx < panic_key_list_len; pkl_idx++) {
      for (kg_idx = 0; panic_key_list[pkl_idx][kg_idx] != 0; kg_idx++) {
        if (!bitset_get(key_flags, panic_key_list[pkl_idx][kg_idx])) {
          supports_panic = false;
          break;
        }
      }
      if (!supports_panic) {
        break;
      }
    }
    if (!supports_panic) {
      continue;
    }

    event_fd_list_len++;
    event_fd_list = safe_reallocarray(event_fd_list, event_fd_list_len, sizeof(int));
    event_fd_list[event_fd_list_len - 1] = tmp_fd;
  }

  if (event_fd_list_len == 0) {
    print(fd_stderr, "Failed to find any input device supporting panic keys!\n");
    exit(1);
  }

  /* Poll setup */
  pollfd_list = safe_calloc(event_fd_list_len + 1, sizeof(struct pollfd));
  for (efl_idx = 0; efl_idx < event_fd_list_len; efl_idx++) {
    pollfd_list[efl_idx].fd = event_fd_list[efl_idx];
    pollfd_list[efl_idx].events = POLLIN;
  }
  pollfd_list[event_fd_list_len].fd = ns;
  pollfd_list[event_fd_list_len].events = POLLIN;

  /* Event loop */
  while (poll(pollfd_list, event_fd_list_len + 1, -1) != -1) {
    /* Panic key handler */
    for (efl_idx = 0; efl_idx < event_fd_list_len; efl_idx++) {
      if (!(pollfd_list[efl_idx].revents & POLLIN)) {
        continue;
      }

      size_t ieread_bytes = read(event_fd_list[efl_idx], ie_buf, sizeof(struct input_event) * 64);

      if (ieread_bytes == -1
        || ieread_bytes == 0
        || (ieread_bytes % sizeof(struct input_event)) != 0) {
        /* This will probably terminate the service if the user unplugs a
         * keyboard or similar, however systemd can start it again. The
         * alternative is to handle device hotplug, which sounds like a
         * recipe for bugs. */
        print(fd_stderr, "Error reading from input device!\n");
        exit(1);
      }

      for (ie_idx = 0; ie_idx < ieread_bytes / sizeof(struct input_event); ie_idx++) {
        if (ie_buf[ie_idx].type != EV_KEY) {
          continue;
        }

        for (pkl_idx = 0; pkl_idx < panic_key_list_len; pkl_idx++) {
          for (kg_idx = 0; panic_key_list[pkl_idx][kg_idx] != 0; kg_idx++) {
            if (ie_buf[ie_idx].code == panic_key_list[pkl_idx][kg_idx]) {
              if (ie_buf[ie_idx].value == 0) {
                panic_key_active_list[pkl_idx] = false;
              } else {
                panic_key_active_list[pkl_idx] = true;
              }
              break; /* only breaks inner loop */
            }
          }
        }

        for (pkl_idx = 0; pkl_idx < panic_key_list_len; pkl_idx++) {
          if (!panic_key_active_list[pkl_idx]) {
            break;
          }
          if (pkl_idx == (panic_key_list_len - 1)) {
            kill_system();
            /*print(fd_stderr, "SHUTDOWN!!!\n");*/
            exit(0);
          }
        }
      }
    }

    /* Netlink socket handler */
    if (pollfd_list[event_fd_list_len].revents & POLLIN) {
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
      struct msghdr msg = { 0 };
      msg.msg_name = &sa2;
      msg.msg_namelen = sizeof(sa2);
      msg.msg_iov = &iov;
      msg.msg_iovlen = 1;
      msg.msg_control = NULL;
      msg.msg_controllen = 0;
      msg.msg_flags = 0;
      char *tmpbuf = NULL;
      bool device_removed = false;
      bool device_changed = false;

      len = recvmsg(ns, &msg, 0);
      if (len == -1) {
        kill_system();
        /*print(fd_stderr, "SHUTDOWN!!!\n");*/
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

      tmpbuf = buf;
      while (len > 0) {
        if (strcmp(tmpbuf, "ACTION=remove") == 0) {
          device_removed = true;
          goto next_str;
        }
        if (strcmp(tmpbuf, "ACTION=change") == 0) {
          device_changed = true;
          goto next_str;
        }

        if (strncmp(tmpbuf, "DEVNAME=", strlen("DEVNAME=")) == 0) {
          if (device_removed || device_changed) {
            char *rem_devname_line = NULL;
            char *rem_dev_name = NULL;

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
            rem_dev_name = strtok(rem_devname_line, "=");
            /* returns the actual device name */
            rem_dev_name = strtok(NULL, "=");
            if (rem_dev_name == NULL) {
              free(rem_devname_line);
              goto next_str;
            }

            if (device_changed && strncmp(rem_dev_name, "sr", 2) != 0) {
              free(rem_devname_line);
              goto next_str;
            }

            for (tdl_idx = 0; tdl_idx < target_dev_list_len; tdl_idx++) {
              if (strcmp(rem_dev_name, target_dev_list[tdl_idx]) == 0) {
                kill_system();
                /*print(fd_stderr, "SHUTDOWN!!!\n");*/
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
}
