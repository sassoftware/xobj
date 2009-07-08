#!/bin/sh
#
# Copyright (c) 2009 rPath, Inc.
#
# This program is distributed under the terms of the MIT License as found 
# in a file called LICENSE. If it is not present, the license
# is always available at http://www.opensource.org/licenses/mit-license.php.
#
# This program is distributed in the hope that it will be useful, but
# without any waranty; without even the implied warranty of merchantability
# or fitness for a particular purpose. See the MIT License for full details.
#
# This could probably be done more elegantly in Python...

pid=''
for ((d=0; d < 20; d++)); do
    DISPLAY=:$d
    Xvfb -ac $DISPLAY > /dev/null 2>&1 &
    sleep 2
    jobs -l %1 > /dev/null
    pid=$(jobs -l %1 2>&1 | grep Running | awk '{print $2}')
    if [ -z "$pid" ]; then
        continue
    fi
    if ps $pid > /dev/null 2>&1; then
        break
    fi
done

if [ -z "$pid" ]; then
    echo "unable to start Xvfb"
    exit 1
fi

trap "kill -9 $pid" SIGINT SIGTERM EXIT

export DISPLAY=$DISPLAY

$*
