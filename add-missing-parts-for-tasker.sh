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

GAPPS_ZIP=gapps-jb-20130812-signed.zip

[ ! -e gapps-jb-20130812-signed.zip ] && echo 'Download gapps-jb-20130812-signed.zip from http://goo.im/gapps/gapps-jb-20130812-signed.zip' && exit 1

echo 'Rooting' && \
    $ADB root && \
    $ADB remount && \
    echo 'extracting files' && \
    for p in system/app/NetworkLocation.apk \
		 system/etc/permissions/com.google.android.maps.xml \
		 system/framework/com.google.android.maps.jar \
		 system/app/GoogleCalendarSyncAdapter.apk \
		 system/app/GoogleContactsSyncAdapter.apk; do
	unzip $GAPPS_ZIP $p || exit 1
	$ADB push ./$p /$p || exit 1
    done && \
    echo 'Rebooting device' && \
    $ADB reboot
