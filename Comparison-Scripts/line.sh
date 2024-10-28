#! /bin/bash

if [[ $(grep -hx "$1" $2) == "$1" ]]; then
    echo "PASS - line.sh"
    exit 0
else
    exit 1
fi
