#!/system/bin/sh

CWD=$(pwd)
IMGFILE=$CWD/slackchroot.img
MOUNTPOINT=$CWD/mnt
CHROOT_SHELL=/bin/zsh

MOUNT='/system/xbin/busybox mount'
CHROOT='/system/xbin/busybox chroot'

mkdir -p $MOUNTPOINT/
$MOUNT -o loop $IMGFILE $MOUNTPOINT/ || exit 1
for m in /proc /dev /sys; do
    $MOUNT -o bind $m $MOUNTPOINT/$m || exit 1
done

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/games:/usr/local/sbin:/usr/sbin:/sbin:$PATH
$CHROOT $MOUNTPOINT/ $CHROOT_SHELL
