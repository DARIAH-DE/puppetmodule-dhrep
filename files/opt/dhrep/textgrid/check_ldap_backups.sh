#!/bin/bash

P1=/var/dhrep/backups/ldap/ldap-backup.ldif.gz
P2=/var/dhrep/backups/ldap/ldap-backup_old.ldif.gz
oneday=$((24*60*60))
twodays=$((2*$oneday))

# Taken from: http://stackoverflow.com/questions/1819187/test-a-file-date-with-bash (THANKS!)

# Test backup
if ! [ -f $P1 ]; then
  echo "LDAP backup CRITICAL: LDAP backup file $P1 does not exist!"
  exit 2
fi

modsecs=$(date --utc --reference=$P1 +%s)
nowsecs=$(date +%s)
delta=$(($nowsecs-$modsecs))

#echo "ldap backup file $P1 was modified $delta secs ago"

if [ $delta -gt $oneday ]; then
  echo "LDAP backup CRITICAL: LDAP backup file $P1 is older than 24h (>$((delta/3600))h)!"
  exit 2
fi

# Test backup of backup
if ! [ -f $P2 ]; then
  echo "LDAP backup WARNING: LDAP backup file $P2 does not exist!"
  exit 1
fi

modsecs=$(date --utc --reference=$P2 +%s)
nowsecs=$(date +%s)
delta2=$(($nowsecs-$modsecs))

#echo "ldap backup file $P2 was modified $delta secs ago"

if [ $delta2 -gt $twodays ]; then
  echo "LDAP backup WARNING: LDAP backup file $P2 is older than 48h (>$((delta2/3600))h)!"
  exit 1
fi

echo "LDAP backup OK: backup files existing and less than 24 hours old (>$((delta/3600))h)"
exit 0
