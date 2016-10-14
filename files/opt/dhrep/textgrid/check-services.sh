#!/bin/bash

SERVER="http://localhost"
CNRM="$(tput sgr0)"
OK="$(tput setaf 2)OK$CNRM"
FAILED="$(tput setaf 1)FAILED$CNRM"
CSTR="$(tput setaf 5)"
VSTR="$(tput setaf 3)"
TRN="  ==>  "

#
# tgauth
#
FILE="tgextra.wsdl"
AUTH=$SERVER"/1.0/tgauth/wsdl/"$FILE
echo "checking "$CSTR"tgauth"$CNRM $TRN $AUTH
wget -q $AUTH
if [ -s $FILE ]; then
    rm $FILE
    echo "    $OK"
else
    echo "    $FAILED"
fi

#
# tgauth-crud
#
FILE="tgextra-crud.wsdl"
AUTH=$SERVER"/1.0/tgauth/wsdl/"$FILE
echo "checking "$CSTR"tgauth_crud"$CNRM $TRN $AUTH
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
echo "checking "$CSTR"tgcrud"$CNRM $TRN $CRUD
wget -q $CRUD
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    cat $FILE
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
fi

#
# tgcrud public
#
FILE="version"
CRUD=$SERVER"/1.0/tgcrud-public/rest/"$FILE
echo "checking "$CSTR"tgcrud public"$CNRM $TRN $CRUD
wget -q $CRUD
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    cat $FILE
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
fi

#
# tgsearch
#
FILE="search?q=fu"
SEARCH=$SERVER"/1.0/tgsearch/"$FILE
echo "checking "$CSTR"tgsearch"$CNRM $TRN $SEARCH
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
echo "checking "$CSTR"tgsearch public"$CNRM $TRN $SEARCH
wget -q $SEARCH
if [ -s $FILE ]; then
    rm $FILE
    echo "    $OK"
else
    echo "    $FAILED"
fi

#
# aggregator
#
FILE="version"
AGGREGATOR=$SERVER"/1.0/aggregator/"$FILE
echo "checking "$CSTR"aggregator"$CNRM $TRN $AGGREGATOR
wget -q $AGGREGATOR
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    URGL=`cat version | grep Version:`;
    echo -n ${URGL#*<em>}
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
fi

#
# tgpublish
#
FILE="version"
PUBLISH=$SERVER"/1.0/tgpublish/"$FILE
echo "checking "$CSTR"tgpublish"$CNRM $TRN $PUBLISH
wget -q $PUBLISH
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    cat $FILE
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
fi

#
# oaipmh
#
FILE="version"
OAIPMH=$SERVER"/1.0/tgoaipmh/oai/"$FILE
echo "checking "$CSTR"tgoaipmh"$CNRM $TRN $OAIPMH
wget -q $OAIPMH
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    cat $FILE
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
fi

#
# pid
#
FILE="version"
PID=$SERVER"/1.0/tgpid/"$FILE
echo "checking "$CSTR"tgpid"$CNRM $TRN $PID
wget -q $PID
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    cat $FILE
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
fi

# 
# digilib
#
INFO="info"
DIGILIB=$SERVER"/1.0/digilib/rest/"$INFO
echo "checking "$CSTR"digilib"$CNRM $TRN $DIGILIB
wget -q $DIGILIB
if [ -s $INFO ]; then
    rm $INFO
    echo "    $OK"
else
    echo "    $FAILED"
fi

#
# static metadata schema
#
FILE="textgrid-metadata_2010.xsd"
SCHEMA=$SERVER"/schema/"$FILE
EQSI=30757
echo "checking "$CSTR"static metadata schema"$CNRM $TRN $SCHEMA
wget -q $SCHEMA
SIZE=$(stat -c%s "$FILE")
rm $FILE
if [ $SIZE -eq $EQSI ]; then
    echo "    $OK [$SIZE == $EQSI]"
else
    echo "    $FAILED [$SIZE != $EQSI]"
fi