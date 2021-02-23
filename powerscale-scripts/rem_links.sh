#! /bin/bash
set -x
ip l | grep tap | awk '{print $2}' | cut -d@ -f 1 | parallel sudo ip link del dev {1}

