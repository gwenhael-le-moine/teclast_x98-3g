#!/bin/sh
# © Copyright 2014 Gwenhael Le Moine

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

CWD=$(pwd)
ADB=${ADB:-$(which adb)}

mkdir -p $CWD/{APKs,bins}/

echo 'Getting Koush Superuser from F-Droid'
APK=com.koushikdutta.superuser_1030.apk
[ -e $CWD/APKs/$APK ] || wget -c https://f-droid.org/repo/$APK -O $CWD/APKs/$APK

echo 'extracting su binary'
unzip  $APK assets/x86/su
mv assets/x86/su $CWD/bins/
rm -fr assets/

[ -e $CWD/bins/su ] || exit 1
[ -e $CWD/$APK ] || exit 1

echo 'Rooting'
$ADB root && \
$ADB remount && \
$ADB push $CWD/bins/su /system/xbin/ && \
$ADB shell chmod 6755 /system/xbin/su && \
$ADB push $CWD/APKs/$APK /system/app/ && \
$ADB shell chmod 6755 /system/app/$APK && \
$ADB reboot
