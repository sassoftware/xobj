#!/bin/sh
#
# Copyright (c) SAS Institute Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


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
