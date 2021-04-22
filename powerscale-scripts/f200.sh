#! /bin/sh

set -e
set -x

MYINSTALLTAR="/tmp/install.tar.gz"
fetch http://172.19.16.1:3928/static/install.tar.gz --output ${MYINSTALLTAR}

gpart add -i 1 -t efi -s 280M da0
gpart add -i 2 -s 2g -t freebsd-ufs da0
newfs_msdos -F 32 -c 1 /dev/da0p1
mount -t msdosfs /dev/da0p1 /mnt
mkdir -p /mnt/EFI/BOOT
cp /boot/loader.efi /mnt/EFI/BOOT/BOOTX64.efi
umount /mnt

newfs -U -L isilon /dev/da0p2
mount /dev/da0p2 /mnt
tar xpf "$MYINSTALLTAR" -C /mnt
echo "/dev/da0p2 / ufs rw 1 1" >> /mnt/etc/fstab
umount /mnt


newfs_msdos -F 32 -c 1 /dev/da1p8
mount -t msdosfs /dev/da1p8 /mnt
mkdir -p /mnt/EFI/BOOT
cp /boot/loader.efi /mnt/EFI/BOOT/BOOTX64.efi
umount /mnt


newfs_msdos -F 32 -c 1 /dev/da4p7
mount -t msdosfs /dev/da4p7 /mnt
mkdir -p /mnt/EFI/BOOT
cp /boot/loader.efi /mnt/EFI/BOOT/BOOTX64.efi
umount /mnt

newfs -U -L isilon /dev/mirror/root1
mount /dev/mirror/root1 /mnt
tar xpf "$MYINSTALLTAR" -C /mnt
echo "/dev/mirror/root1 / ufs rw 1 1" >> /mnt/etc/fstab
umount /mnt


/usr/bin/isi_hwtools/isi_psi_tool -v
fsck /dev/mirror/mfg

newfs -U /dev/mirror/mfg

mount /dev/mirror/mfg /mnt
mkdir /mnt/psi
fetch http://172.19.16.1:3928/static/psf.json --output /mnt/psi/psf.json
umount /mnt

