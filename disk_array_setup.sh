#!/bin/bash

dnf install -y gcc make
curl -LO https://github.com/amadvance/snapraid/releases/download/v12.0/snapraid-12.0.tar.gz
tar zxvf snapraid-12.0.tar.gz
cd snapraid-12.0/
./configure
make
make check
make install
cd ..
cp ~/snapraid-12.0/snapraid.conf.example /etc/snapraid.conf
rm -rf snapraid-12.0*

parted -a optimal -s /dev/sdb -- mklabel gpt mkpart primary xfs 1 -1 align-check optimal 1
parted -a optimal -s /dev/sdc -- mklabel gpt mkpart primary xfs 1 -1 align-check optimal 1
parted -a optimal -s /dev/sdd -- mklabel gpt mkpart primary xfs 1 -1 align-check optimal 1
parted -a optimal -s /dev/sde -- mklabel gpt mkpart primary xfs 1 -1 align-check optimal 1
parted -a optimal -s /dev/sdf -- mklabel gpt mkpart primary xfs 1 -1 align-check optimal 1
parted -a optimal -s /dev/sdg -- mklabel gpt mkpart primary xfs 1 -1 align-check optimal 1
parted -a optimal -s /dev/sdh -- mklabel gpt mkpart primary xfs 1 -1 align-check optimal 1
parted -a optimal -s /dev/sdi -- mklabel gpt mkpart primary xfs 1 -1 align-check optimal 1
parted -a optimal -s /dev/sdj -- mklabel gpt mkpart primary xfs 1 -1 align-check optimal 1
parted -a optimal -s /dev/sdk -- mklabel gpt mkpart primary xfs 1 -1 align-check optimal 1

mkdir -p /mnt/data/disk{1..8}
mkdir -p /mnt/parity/disk{1,2}

mkfs.xfs /dev/sdb1
mkfs.xfs /dev/sdc1
mkfs.xfs /dev/sdd1
mkfs.xfs /dev/sde1
mkfs.xfs /dev/sdf1
mkfs.xfs /dev/sdg1
mkfs.xfs /dev/sdh1
mkfs.xfs /dev/sdi1
mkfs.xfs /dev/sdj1
mkfs.xfs /dev/sdk1

blkid -s UUID -o value /dev/sd{b..k}1 | head -8 | xargs -I% echo "UUID=% /mnt/data/disk xfs defaults 0 2" | awk '{print $1,$2 NR,$3,$4,$5,$6}' >> /etc/fstab
blkid -s UUID -o value /dev/sd{b..k}1 | tail -2 | xargs -I% echo "UUID=% /mnt/parity/disk xfs defaults 0 2" | awk '{print $1,$2 NR,$3,$4,$5,$6}' >> /etc/fstab

mount -a

cat << 'EOS' > /etc/snapraid.conf
# Example configuration for snapraid

# Defines the file to use as parity storage
# It must NOT be in a data disk
# Format: "parity FILE [,FILE] ..."
parity /mnt/parity/disk1/snapraid.parity

# Defines the files to use as additional parity storage.
# If specified, they enable the multiple failures protection
# from two to six level of parity.
# To enable, uncomment one parity file for each level of extra
# protection required. Start from 2-parity, and follow in order.
# It must NOT be in a data disk
# Format: "X-parity FILE [,FILE] ..."
2-parity /mnt/parity/disk2/snapraid.2-parity
#3-parity /mnt/diskr/snapraid.3-parity
#4-parity /mnt/disks/snapraid.4-parity
#5-parity /mnt/diskt/snapraid.5-parity
#6-parity /mnt/disku/snapraid.6-parity

# Defines the files to use as content list
# You can use multiple specification to store more copies
# You must have least one copy for each parity file plus one. Some more don't hurt
# They can be in the disks used for data, parity or boot,
# but each file must be in a different disk
# Format: "content FILE"
content /var/snapraid.content
content /mnt/data/disk1/snapraid.content
content /mnt/data/disk2/snapraid.content
content /mnt/data/disk3/snapraid.content
content /mnt/data/disk4/snapraid.content
content /mnt/data/disk5/snapraid.content
content /mnt/data/disk6/snapraid.content
content /mnt/data/disk7/snapraid.content
content /mnt/data/disk8/snapraid.content

# Defines the data disks to use
# The name and mount point association is relevant for parity, do not change it
# WARNING: Adding here your /home, /var or /tmp disks is NOT a good idea!
# SnapRAID is better suited for files that rarely changes!
# Format: "data DISK_NAME DISK_MOUNT_POINT"
data d1 /mnt/data/disk1/
data d2 /mnt/data/disk2/
data d3 /mnt/data/disk3/
data d4 /mnt/data/disk4/
data d5 /mnt/data/disk5/
data d6 /mnt/data/disk6/
data d7 /mnt/data/disk7/
data d8 /mnt/data/disk8/

# Excludes hidden files and directories (uncomment to enable).
#nohidden

# Defines files and directories to exclude
# Remember that all the paths are relative at the mount points
# Format: "exclude FILE"
# Format: "exclude DIR/"
# Format: "exclude /PATH/FILE"
# Format: "exclude /PATH/DIR/"
exclude *.unrecoverable
exclude /lost+found/

# Defines the block size in kibi bytes (1024 bytes) (uncomment to enable).
# WARNING: Changing this value is for experts only!
# Default value is 256 -> 256 kibi bytes -> 262144 bytes
# Format: "blocksize SIZE_IN_KiB"
blocksize 64

# Defines the hash size in bytes (uncomment to enable).
# WARNING: Changing this value is for experts only!
# Default value is 16 -> 128 bits
# Format: "hashsize SIZE_IN_BYTES"
#hashsize 16

# Automatically save the state when syncing after the specified amount
# of GB processed (uncomment to enable).
# This option is useful to avoid to restart from scratch long 'sync'
# commands interrupted by a machine crash.
# It also improves the recovering if a disk break during a 'sync'.
# Default value is 0, meaning disabled.
# Format: "autosave SIZE_IN_GB"
#autosave 500

# Defines the pooling directory where the virtual view of the disk
# array is created using the "pool" command (uncomment to enable).
# The files are not really copied here, but just linked using
# symbolic links.
# This directory must be outside the array.
# Format: "pool DIR"
#pool /pool

# Defines a custom smartctl command to obtain the SMART attributes
# for each disk. This may be required for RAID controllers and for
# some USB disk that cannot be autodetected.
# In the specified options, the "%s" string is replaced by the device name.
# Refers at the smartmontools documentation about the possible options:
# RAID -> https://www.smartmontools.org/wiki/Supported_RAID-Controllers
# USB -> https://www.smartmontools.org/wiki/Supported_USB-Devices
#smartctl d1 -d sat %s
#smartctl d2 -d usbjmicron %s
#smartctl parity -d areca,1/1 /dev/sg0
#smartctl 2-parity -d areca,2/1 /dev/sg0
EOS

/usr/local/bin/snapraid sync

dnf install -y https://github.com/trapexit/mergerfs/releases/download/2.33.3/mergerfs-2.33.3-1.el8.x86_64.rpm

echo "/mnt/data/* /storage fuse.mergerfs allow_other,use_ino,cache.files=partial,moveonenospc=true,dropcacheonclose=true,category.create=mfs,fsname=mergerfsPool 0 0" >> /etc/fstab
mkdir /storage
mount /storage
