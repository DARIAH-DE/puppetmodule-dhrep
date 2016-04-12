#!/bin/bash

# First get newest nonpublic and public filenames
P1=`ls -r1t /var/textgrid/backups/sesame/openrdf_textgrid-nonpublic*.rdf.gz | tail -1` 
P2=`ls -r1t /var/textgrid/backups/sesame/openrdf_textgrid-public*.rdf.gz | tail -1`
oneday=$((24*60*60))

# Taken from: http://stackoverflow.com/questions/1819187/test-a-file-date-with-bash (THANKS!)

# Test nonpublic sesame backup file
if [ -z $P1 ]; then
  echo "SESAME backup CRITICAL (nonpublic): No SESAME backup files existing at all!"
  exit 2
fi
if ! [ -f $P1 ]; then
  echo "SESAME backup CRITICAL (nonpublic): SESAME backup file [$P1] does not exist!"
  exit 2
fi

modsecs=$(date --utc --reference=$P1 +%s)
nowsecs=$(date +%s)
delta=$(($nowsecs-$modsecs))

#echo "sesame backup file $P1 was modified $delta secs ago"

if [ -z $P2 ]; then
  echo "SESAME backup CRITICAL (nonpublic): No SESAME backup files existing at all!"
  exit 2
fi
if [ $delta -gt $oneday ]; then
  echo "SESAME backup CRITICAL (nonpublic): SESAME backup file [$P1] is older than 24h!"
  exit 2
fi

# Test public sesame backup file
if ! [ -f $P2 ]; then
  echo "SESAME backup CRITICAL (public): SESAME backup file [$P2] does not exist!"
  exit 2
fi

modsecs=$(date --utc --reference=$P2 +%s)
nowsecs=$(date +%s)
delta=$(($nowsecs-$modsecs))

#echo "sesame backup file $P2 was modified $delta secs ago"

if [ $delta -gt $oneday ]; then
  echo "SESAME backup CRITICAL (public): SESAME backup file [$P2] is older than 24h!"
  exit 2
fi

echo "SESAME backups OK: nonpublic and public backup files existing and less than 24h old"
exit 0
