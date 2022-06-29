#!/bin/sh

echo "Checking for mounted disks..."
dmsetup ls --target crypt
echo "WIPE RAM!"
## TODO: remove -f
sdmem -f
echo "WIPE DONE!"
