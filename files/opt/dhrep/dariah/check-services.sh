#!/bin/bash

#
# generics
#
SERVER="http://localhost"
CNRM="$(tput sgr0)"
OK="$(tput setaf 2)OK$CNRM"
FAILED="$(tput setaf 1)FAILED$CNRM"
CSTR="$(tput setaf 5)"
VSTR="$(tput setaf 3)"
TRN="  ==>  "
ERRORS=false

#
# dhcrud
#
FILE="version"
CRUD=$SERVER":9093/dhcrud-public/"$FILE
echo "checking "$CSTR"dhcrud"$CNRM $TRN $CRUD
wget -q $CRUD
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    cat $FILE
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    ERRORS=true
fi

#
# dhcrud public
#
FILE="version"
CRUD=$SERVER":9093/dhcrud/"$FILE
echo "checking "$CSTR"dhcrud public"$CNRM $TRN $CRUD
wget -q $CRUD
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    cat $FILE
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    ERRORS=true
fi

#
# dhpublish
#
FILE="version"
PUBLISH=$SERVER"/dhpublish/"$FILE
echo "checking "$CSTR"dhpublish"$CNRM $TRN $PUBLISH
wget -q $PUBLISH
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    cat $FILE
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    ERRORS=true
fi

#
# oaipmh
#
FILE="version"
OAIPMH=$SERVER"/oaipmh/oai/"$FILE
echo "checking "$CSTR"oaipmh"$CNRM $TRN $OAIPMH
wget -q $OAIPMH
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    cat $FILE
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    ERRORS=true
fi

#
# pid
#
FILE="version"
PID=$SERVER":9094/dhpid/"$FILE
echo "checking "$CSTR"dhpid"$CNRM $TRN $PID
wget -q $PID
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    cat $FILE
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    ERRORS=true
fi

#
# elasticsearch masternode
#
#FILE="curl"
#MASTERNODE=$SERVER":9092"
#echo "checking "$CSTR"elasticsearch masternode"$CNRM $TRN $curl
#curl $MASTERNODE
#if [ -s $FILE ]; then
#    echo -n "    $OK ["$VSTR
#    cat $FILE
#    rm $FILE
#    echo §CNRM"]"
#else
#    echo "    $FAILED"
#    ERRORS=true
#fi

#
# elasticsearch workhorse
#

#
# check for errors
#
if $ERRORS ; then
    echo "...service check $FAILED with exit code 1!"
    exit 1
fi

echo "...service check turns out to be $OK"
exit 0
