#!/bin/bash

P1=/var/textgrid/backups/ldap/ldap-backup.ldif
P2=/var/textgrid/backups/ldap/ldap-backup_old.ldif
oneday=$((24*60*60))
twodays=$((2*$oneday))

# Taken from: http://stackoverflow.com/questions/1819187/test-a-file-date-with-bash (THANKS!)

# Test backup
if [ -f $P1 ]; then
  echo "ldap backup file $P1 is existing"
  echo "ok"
else
  echo "critical: ldap backup file $P1 does not exist!"
  exit 2
fi

modsecs=$(date --utc --reference=$P1 +%s)
nowsecs=$(date +%s)
delta=$(($nowsecs-$modsecs))

echo "ldap backup file $P1 was modified $delta secs ago"

if [ $delta -gt $oneday ]; then
  echo "critical: ldap backup file [$P1] is older than 24h!"
  exit 2
else
  echo "ok"
fi

# Test backup of backup
if [ -f $P2 ]; then
  echo "ldap backup file $P2 is existing"
  echo "ok"
else
  echo "warning: ldap backup file $P2 does not exist!"
  exit 1
fi

modsecs=$(date --utc --reference=$P2 +%s)
nowsecs=$(date +%s)
delta=$(($nowsecs-$modsecs))

echo "ldap backup file $P2 was modified $delta secs ago"

if [ $delta -gt $twodays ]; then
  echo "warning: ldap backup file [$P2] is older than 48h!"
  exit 1
else
  echo "ok"
fi
exit 0
