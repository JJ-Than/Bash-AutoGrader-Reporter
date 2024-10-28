#! /bin/bash

ALGORITHM=$(cat './Config.json' | jq -r '.hash_program')

hash=$($ALGORITHM $2 | awk '{print $1}')

if [[ $1 == $hash ]]; then
    echo "PASS - hash.sh"
    exit 0
else
    exit 1
fi
