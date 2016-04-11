#!/bin/bash

P1=`ls -r1t rbacusers-*.csv | tail -1` 
P2=`ls -r1t rbacusers-*.txt | tail -1`
onemonth=$((31*24*60*60))

# Taken from: http://stackoverflow.com/questions/1819187/test-a-file-date-with-bash (THANKS!)

# Test statistic CSV file
if [ -f $P1 ]; then
  echo "ldap statistic $P1 is existing"
  echo "ok"
else
  echo "critical: ldap statistic file $P1 does not exist!"
  exit 2
fi

modsecs=$(date --utc --reference=$P1 +%s)
nowsecs=$(date +%s)
delta=$(($nowsecs-$modsecs))

echo "ldap statistic file $P1 was modified $delta secs ago"

if [ $delta -gt $onemonth ]; then
  echo "critical: ldap statistic file [$P1] is older than one month!"
  exit 2
else
  echo "ok"
fi

# Test statistic TXT file
if [ -f $P2 ]; then
  echo "ldap statistic $P2 is existing"
  echo "ok"
else
  echo "critical: ldap statistic file $P2 does not exist!"
  exit 2
fi

modsecs=$(date --utc --reference=$P2 +%s)
nowsecs=$(date +%s)
delta=$(($nowsecs-$modsecs))

echo "ldap statistic file $P2 was modified $delta secs ago"

if [ $delta -gt $onemonth ]; then
  echo "critical: ldap statistic file [$P2] is older than one month!"
  exit 2
else
  echo "ok"
fi

exit 0
