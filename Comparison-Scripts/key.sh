#! /bin/bash

if [[ `grep -ch $1 $2` == 1 ]]; then
    echo "PASS - key.sh"
    exit 0
else
    exit 1
fi
