#!/bin/sh

echo "Checking for mounted disks..."
dmsetup ls --target crypt
echo "WIPE RAM!"
## TODO: remove -f (fast and insecure mode)
sdmem -v -f
echo "WIPE DONE!"
