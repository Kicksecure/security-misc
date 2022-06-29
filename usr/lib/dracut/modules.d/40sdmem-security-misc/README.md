### Make sure sdmem and dmsetup is part of the initramfs

sudo apt update

sudo apt --no-install-recommends install secure-delete dmsetup

sudo dracut --include /usr/bin/sdmem /bin/sdmem --force
