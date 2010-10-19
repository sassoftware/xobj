#!/bin/sh
#
# Copyright (c) 2009-2010 rPath, Inc.
# All rights reserved
#
# Get the build version for build.xml
#
# This program is distributed under the terms of the MIT License as found 
# in a file called LICENSE. If it is not present, the license
# is always available at http://www.opensource.org/licenses/mit-license.php.
#
# This program is distributed in the hope that it will be useful, but
# without any warranty; without even the implied warranty of merchantability
# or fitness for a particular purpose. See the MIT License for full details.

hgDir=$1
if [ -z $hgDir ]; then
  hgDir=../../
fi

if [[ -x /usr/bin/hg && -d $hgDir/.hg ]] ; then
    rev=`hg id -i`
elif [[ -x /usr/local/bin/hg && -d $hgDir/.hg ]]; then
    rev=`hg id -i`
elif [ -f $hgDir/.hg_archival.txt ]; then
    rev=`grep node $hgDir/.hg_archival.txt |cut -d' ' -f 2 |head -c 12`;
else
    rev= ;
fi ;
echo "$rev"


