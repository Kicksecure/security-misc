#!/bin/sh

echo "Checking for mounted disks..."
dmsetup ls --target crypt
echo "WIPE RAM!"
sdmem -f
echo "WIPE DONE!"
