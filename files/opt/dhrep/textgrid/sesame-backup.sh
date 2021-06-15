#!/bin/bash

BACKUP_DIR=/var/dhrep/backups/sesame
SESAME_URL=http://localhost:9091/openrdf-sesame
CONTENT_TYPE=application/x-turtle
REPOS="textgrid-nonpublic textgrid-public"

# backup a given repository on the server
# $1 repository name
function backup_openrdf_repository {
  local REPO=$1
  local TS=$(date +%Y-%m-%d_%T)
  local OUTFILE=$BACKUP_DIR/openrdf_$REPO"_"$TS.rdf
  local CURL_OUT=$(curl -s --header "Accept: $CONTENT_TYPE" $SESAME_URL/repositories/$REPO/statements -o "$OUTFILE" -w %{http_code})
  # if backup failed -> delete file, else gzip
  if [ $CURL_OUT -eq "200" ]
    then
      gzip $OUTFILE
      return 0
    else
      rm $OUTFILE
      return $CURL_OUT
  fi
}

for R in $REPOS
do
  backup_openrdf_repository $R
done

