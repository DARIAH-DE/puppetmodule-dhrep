#!/bin/bash

URL=$1   # the url to test
RETRY=$2 # num retries

i=0
while [ $i -le $RETRY ]; do
    wget --spider --read-timeout=20 --timeout=15 $URL
    if [ $? = 0 ]; then 
        exit 0 
    fi;
    sleep 1s;
    ((i++))
done;

exit 1
