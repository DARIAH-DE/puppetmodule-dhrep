#!/bin/bash

SERVER="http://localhost"
OK="$(tput setaf 2)OK$(tput sgr0)"
FAILED="$(tput setaf 1)FAILED!$(tput sgr0)"

#
# tgauth
#
FILE="tgextra.wsdl"
AUTH=$SERVER"/1.0/tgauth/wsdl/"$FILE
echo "checking $(tput setaf 5)tgauth$(tput sgr0) on "$AUTH
wget -q $AUTH
if [ -s $FILE ]; then
    rm $FILE
    echo "    $OK"
else
    echo "    $FAILED"
fi

#
# tgauth pubic
#
FILE="tgextra-crud.wsdl"
AUTH=$SERVER"/1.0/tgauth/wsdl/"$FILE
echo "checking $(tput setaf 5)tgauth_crud$(tput sgr0) on "$AUTH
wget -q $AUTH
if [ -s $FILE ]; then
    rm $FILE
    echo "    $OK"
else
    echo "    $FAILED"
fi

#
# tgcrud
#
FILE="version"
CRUD=$SERVER"/1.0/tgcrud/rest/"$FILE
echo "checking $(tput setaf 5)tgcrud$(tput sgr0) service on "$CRUD
wget -q $CRUD
if [ -s $FILE ]; then
    echo -n "    $OK ["
    cat $FILE
    rm $FILE
    echo "]"
else
    echo "    $FAILED"
fi

#
# tgcrud public
#
FILE="version"
CRUD=$SERVER"/1.0/tgcrud-public/rest/"$FILE
echo "checking $(tput setaf 5)tgcrud public$(tput sgr0) service on "$CRUD
wget -q $CRUD
if [ -s $FILE ]; then
    echo -n "    $OK ["
    cat $FILE
    rm $FILE
    echo "]"
else
    echo "    $FAILED"
fi

#
# tgsearch
#
FILE="search?q=fu"
SEARCH=$SERVER"/1.0/tgsearch/"$FILE
echo "checking $(tput setaf 5)tgsearch$(tput sgr0) on "$SEARCH
wget -q $SEARCH
if [ -s $FILE ]; then
    rm $FILE
    echo "    $OK"
else
    echo "    $FAILED"
fi

#
# tgsearch public
#
FILE="search?q=fu"
SEARCH=$SERVER"/1.0/tgsearch-public/"$FILE
echo "checking $(tput setaf 5)tgsearch public$(tput sgr0) on "$SEARCH
wget -q $SEARCH
if [ -s $FILE ]; then
    rm $FILE
    echo "    $OK"
else
    echo "    $FAILED"
fi

#
# TODO aggregator
#

#
# tgpublish
#
FILE="version"
PUBLISH=$SERVER"/1.0/tgpublish/"$FILE
echo "checking $(tput setaf 5)tgpublish$(tput sgr0) on "$PUBLISH
wget -q $PUBLISH
if [ -s $FILE ]; then
    echo -n "    $OK ["
    cat $FILE
    rm $FILE
    echo "]"
else
    echo "    $FAILED"
fi

#
# tgoaipmh
#
FILE="oai?verb=Identify"
OAIPMH=$SERVER"/1.0/tgoaipmh/"$FILE
echo "checking $(tput setaf 5)tgoaipmh$(tput sgr0) on "$OAIPMH
wget -q $OAIPMH
if [ -s $FILE ]; then
    rm $FILE
    echo "    $OK"
else
    echo "    $FAILED"
fi

#
# tgpid
#
FILE="version"
TGPID=$SERVER"/1.0/tgpid/"$FILE
echo "checking $(tput setaf 5)tgpid$(tput sgr0) on "$TPID
wget -q $TGPID
if [ -s $FILE ]; then
    echo -n "    $OK ["
    cat $FILE
    rm $FILE
    echo "]"
else
    echo "    $FAILED"
fi

#
# static metadata schema
#
FILE="textgrid-metadata_2010.xsd"
SCHEMA=$SERVER"/schema/"$FILE
EQSI=30757
echo "checking $(tput setaf 5)static metadata schema$(tput sgr0) on "$SCHEMA
wget -q $SCHEMA
SIZE=$(stat -c%s "$FILE")
rm $FILE
if [ $SIZE -eq $EQSI ]; then
    echo "    $OK [$SIZE == $EQSI]"
else
    echo "    $FAILED [$SIZE != $EQSI]"
fi
