#!/bin/sh

# Copyright 2010  Stuart Winter, Surrey, England, UK.
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
##############################################################################
# Script : build_minirootfs.sh
# Purpose: Build a mini Slackware root filesystem.
#          The mini root filesystem is a useful tool for embedded developers
#          who want a pre-made basic system from which to build on, or to
#          have a small but working OS to squeeze onto a low capacity 
#          storage device such as NAND.
#          One of the other features is that it can be used in the bootstrap
#          process of supporting a new device.
# Author:  Stuart Winter <mozes@slackware.com>
# Date::   04-Feb-2010
###############################################################################

# Gwenhael Le Moine
# 2014-06-18: Added some necessary packages

####### Usage #################################################################
# This script must be run on the architecture for which you are
# producing the mini rootfs (i.e. you for Slackware ARM you need
# to run this on an ARM machine, not an x86).
#
# You need to run this script inside the root of your Slackware tree.
#
#   # cd armedslack-current
#   # <path/to/this/script>

##############

# Set your host name:
NEWHOST="slackware.localdomain"
ROOTPASS="password"

# Temporary location where the root filesystem will be created:
INSTLOC=/tmp/miniroot/

# You're running this script from in, say, armedslack-current:
SOURCEDIR=$PWD

if [ ! -d slackware ]; then
   echo "Unable to find slackware package directory"
   exit 1
fi

rm -rf $INSTLOC
mkdir -vpm755 $INSTLOC

# Populate with your package list:
PKGLIST="a/aaa_base \
a/aaa_elflibs \
a/aaa_terminfo \
a/acl \
a/attr \
a/bash \
a/bin \
a/bzip2 \
a/coreutils \
a/cxxlibs \
a/dbus \
a/dcron \
a/devs \
a/dialog \
a/e2fsprogs \
a/ed \
a/elvis \
a/etc \
a/file \
a/lvm2 \
a/less \
a/findutils \
a/gawk \
a/gettext \
a/getty-ps \
a/glibc-solibs \
a/glibc-zoneinfo \
a/gptfdisk \
a/grep \
a/gzip \
a/kbd \
a/jfsutils \
a/inotify-tools \
a/kmod \
a/mtd-utils \
a/openssl-solibs \
a/pkgtools \
a/procps \
a/reiserfsprogs \
a/shadow \
a/sed \
a/sysklogd \
a/sysvinit \
a/sysvinit-scripts \
a/tar \
a/u-boot-tools \
a/udev \
a/usbutils \
a/util-linux \
a/vboot-utils \
a/which \
a/xfsprogs \
a/xz
ap/nano \
ap/slackpkg \
ap/zsh \
ap/jed \
n/dhcpcd \
n/lftp \
n/links \
n/network-scripts \
n/nfs-utils \
n/ntp \
n/iputils* \
n/net-tools \
n/iproute2 \
n/openssh \
n/portmap \
n/rsync \
n/telnet \
n/traceroute \
n/wget \
n/wpa_supplicant \
n/wireless-tools \
l/lzo \
l/libnl3"

# Not any more.  For most users this means they have to removepkg them
# in order to use the miniroot for an unsupported system, so let's just leave
# them out.
#a/kernel-modules* \
#a/kernel_[a-z]* \

# Install packages into the mini root filesystem:
for PKG in $PKGLIST ; do
  # This pushing & poping is done because we populate our package list outside
  # of the "slackware" directory in order to not expand "kernel_*" in the list above.
  # So now we enter into the "slackware" directory and install the given
  # package names.
  #
  # Check if there's a version in 'patches' (useful if rebuilding a stable release's mini root)
  if [ -f patches/packages/${PKG#*/}-[0-9]*.t?z ]; then
     # Found in '/patches':
     pushd patches/packages > /dev/null
     installpkg -root $INSTLOC ${PKG#*/}-[0-9]*.t?z
   else
     # Assume it's in the '/slackware' dir
     pushd slackware > /dev/null
     installpkg -root $INSTLOC $PKG-[0-9]*.t?z
   fi
  popd > /dev/null 
done

#### Configure the system ############################################################

cd $INSTLOC

# Update ld.so.conf:
cat << EOF >> etc/ld.so.conf
/lib
/usr/lib
EOF
ldconfig -r $INSTLOC

# Create fstab.
# This needs to be updated by the admin prior to use.
cat << EOF > etc/fstab
#
# Sample /etc/fstab 
# 
# This must be modified prior to use.
# 
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
proc            /proc           proc    defaults        0       0
#
# tmpfs            /dev/shm         tmpfs       defaults         0   0
#
##############################################################################
# This sample fstab comes from the Slackware ARM 'build_minirootfs.sh' script.
# 
#
# The Slackware ARM installation documents recommend creating a separate /boot
# partition that uses the ext2 filesystem so that u-boot can load the kernels
# & initrd from it:
#/dev/sda1       /boot           ext2    errors=remount-ro 0       1

# Swap:
#/dev/sda2       none            swap    sw                0       0

# The rest is for the root filesystem:
#/dev/sda3       /               ext4    errors=remount-ro 0       1
EOF

# Update your resolver details:
cat << EOF > etc/resolv.conf
# These values were configured statically for the Slackware ARM
# mini rootfs.  You need to change them to suit your environment, or
# use dhcpcd to obtain your network settings automatically if
# you run DHCP on your network.
search localdomain
nameserver 192.168.1.1
EOF

# I need SSHd and RPC for NFS running at boot:
chmod +x etc/rc.d/rc.{ssh*,rpc}

# Set the timezone to Europe/London. You should use '/usr/sbin/timeconfig' to
# change this if you're not in the UK.
( cd etc
  cat << EOF > hardwareclock
# /etc/hardwareclock
#
# Tells how the hardware clock time is stored.
# You should run timeconfig to edit this file.

localtime
EOF

  rm -f localtime*
  ln -vfs /usr/share/zoneinfo/Europe/London localtime-copied-from
  cp -favv $INSTLOC/usr/share/zoneinfo/Europe/London localtime )

# Set the keymap:
# We'll set this to the UK keymap, but you might want to change it
# to your own locale!
cat << EOF > etc/rc.d/rc.keymap
#!/bin/sh
# Load the keyboard map.  More maps are in /usr/share/kbd/keymaps.
if [ -x /usr/bin/loadkeys ]; then
 /usr/bin/loadkeys uk.map
fi
EOF
chmod 755 etc/rc.d/rc.keymap

# Set the host name:
echo $NEWHOST > etc/HOSTNAME

# Update fonts so that X and xVNC will work:
if [ -d usr/share/fonts/ ]; then
   ( cd usr/share/fonts/
     find . -type d -mindepth 1 -maxdepth 1 | while read dir ; do
     ( cd $dir
        mkfontscale .
        mkfontdir . )
     done
   /usr/bin/fc-cache -f )
fi

# Set default window manager to WindowMaker because it's light weight
# and therefore fast.
if [ -d etc/X11/xinit/ ]; then
   ( cd etc/X11/xinit/
     ln -vfs xinitrc.wmaker xinitrc )
fi

# Allow root login on the first serial port 
# (useful for SheevaPlugs, Marvell OpenRD systems, and numerous others)
sed -i 's?^#ttyS0?ttyS0?' etc/securetty
# Start a login on the first serial port:
# Only add the line if it's absent -- since I usually use a Marvell ARM device to
# build these images, the post install scripts for some packages will detect
# "Marvell" in /proc/cpuinfo, and adjust these config files during installation.
grep -q '^s0:.*ttyS0.*vt100' etc/inittab || sed -i '/^# Local serial lines:/ a\s0:12345:respawn:/sbin/agetty 115200 ttyS0 vt100' etc/inittab

# Set root password:
cat << EOF > tmp/setrootpw
/usr/bin/echo "root:$ROOTPASS" | /usr/sbin/chpasswd
EOF
chmod 755 tmp/setrootpw
chroot $INSTLOC /tmp/setrootpw
rm -f tmp/setrootpw
# Log the root password so that we can document it in the "details"
# file for each rootfs.  This file will be wiped by the archiving script.
echo "$ROOTPASS" > tmp/rootpw

# Write out the build date of this image:
cat << EOF > root/rootfs_build_date
This mini root filesystem was built on:
$( date -u )
EOF

# Set eth0 to be DHCP by default
sed -i 's?USE_DHCP\[0\]=.*?USE_DHCP\[0\]="yes"?g' etc/rc.d/rc.inet1.conf 

# Create SSH keys.  
# It's expected that the admins will replace these if they wish to use the mini
# root permanently:
echo "Generating SSH keys for the mini root"
# So we can set the host name that generated the SSH keys:
# this library is stored in the slackkit package.
[ -s /usr/lib/libfakeuname.so ] && cp -fav /usr/lib/libfakeuname.so usr/lib/
cat << EOF > tmp/sshkeygen
export LD_PRELOAD=/usr/lib/libfakeuname.so
export FAKEUNAME=slackware-miniroot
/usr/bin/ssh-keygen -t rsa1 -f /etc/ssh/ssh_host_key -N ''
/usr/bin/ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''
/usr/bin/ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
EOF
chmod 755 tmp/sshkeygen
chroot $INSTLOC /tmp/sshkeygen
rm -f tmp/sshkeygen
rm -f usr/lib/libfakeuname.so

# e2fsck v1.4.x needs a RTC which QEMU emulating ARM does not have
# so we need to tell it to be happy anyway.
# Normally we only do this if e2fsprogs finds itself being installed
# on an "ARM Versatile" board, but since we don't prepare these mini roots
# on such a system, but we may well use it on one, we will configure e2fsprogs
# in this way.
cat << EOF > etc/e2fsck.conf
# These options stop e2fsck from erroring/requiring manual intervention
# when it encounters bad time stamps on filesystems -- which happens on
# the Versatile platform because QEMU does not have RTC (real time clock)
# support.
#
[options]
        accept_time_fudge = 1
        broken_system_clock = 1
EOF

# Check the installation works:
cat << EOF
*****************************************************************
Dropping into chroot NOW 
Test this works.  We might need additional packages if there are
new dependencies.

exit the chroot to continue packaging this filesystem.
*****************************************************************
EOF

chroot $INSTLOC /bin/bash -l
echo "chroot finished."

#EOF
