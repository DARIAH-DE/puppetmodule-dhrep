#!/bin/bash

# First get newest CSV and TXT filenames
P1=`ls -r1t /var/dhrep/statistics/ldap/rbacusers-*.csv | tail -1` 
P2=`ls -r1t /var/dhrep/statistics/ldap/rbacusers-*.txt | tail -1`
onemonth=$((31*24*60*60))

# Taken from: http://stackoverflow.com/questions/1819187/test-a-file-date-with-bash (THANKS!)

# Test statistic CSV file
if ! [ -f $P1 ]; then
  echo "LDAP statistic CRITICAL: LDAP statistic file $P1 does not exist!"
  exit 2
fi

modsecs=$(date --utc --reference=$P1 +%s)
nowsecs=$(date +%s)
delta=$(($nowsecs-$modsecs))

#echo "ldap statistic file $P1 was modified $delta secs ago"

if [ $delta -gt $onemonth ]; then
  echo "LDAP statistics CRITICAL: LDAP statistic file $P1 is older than one month (>$(($delta/(24*3600)))d)!"
  exit 2
fi

# Test statistic TXT file
if ! [ -f $P2 ]; then
  echo "LDAP statistics CRITICAL: LDAP statistic file $P2 does not exist!"
  exit 2
fi

modsecs=$(date --utc --reference=$P2 +%s)
nowsecs=$(date +%s)
delta=$(($nowsecs-$modsecs))

#echo "ldap statistic file $P2 was modified $delta secs ago"

if [ $delta -gt $onemonth ]; then
  echo "LDAP statistics CRITICAL: LDAP statistic file $P2 is older than one month (>$(($delta/(24*3600)))d)!"
  exit 2
fi

echo "LDAP statistics OK: statistic files existing and less than one month old (>$(($delta/(24*3600)))d)"
exit 0
