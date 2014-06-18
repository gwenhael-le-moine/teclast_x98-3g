#!/system/bin/sh

for m in /proc /sys /dev /; do
    umount /storage/sdcard_ext/Slackware/mnt$m;
done
