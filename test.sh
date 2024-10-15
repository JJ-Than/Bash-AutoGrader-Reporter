#! /bin/bash

NUMBER_OF_KEYS=""
Test_Case=$(sed -E 's/["]Number_Of_Keys[":]{2}\s?([0-9]{1,})/\1/p' ./Config.json)
if [ -z $Test_Case ]; then
    echo $Test_Case
else
    echo "foo"
fi