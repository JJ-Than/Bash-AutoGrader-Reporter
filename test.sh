#! /bin/bash

NUMBER_OF_KEYS=""
Test_Case=$(grep -E '\"Number_Of_Keys\":([0-9]{1,})' ./Config.json)
if [[ -v Test_Case ]]; then
    cat ./Config.json | jq -r '.Properties.Number_Of_Keys'
else
    echo "foo"
fi