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
    rm -f $FILE
    ERRORS=true
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
    rm -f $FILE
    ERRORS=true
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
    rm -f $FILE
    ERRORS=true
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
    rm -f $FILE
    ERRORS=true
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
    rm -f $FILE
    ERRORS=true
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
    rm -f $FILE
    ERRORS=true
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
    rm -f $FILE
    ERRORS=true
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
    rm -f $FILE
    ERRORS=true
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
    rm -f $FILE
    ERRORS=true
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
    rm -f $FILE
    ERRORS=true
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
    rm -f $FILE
    ERRORS=true
fi

#
# sesame nonpublic
#
FILE="curl"
SESAME=$SERVER"/1.0/triplestore?query=info"
echo "checking "$CSTR"sesame nonpublic"$CNRM $TRN $SESAME
curl -s $SESAME > $FILE
URGL=`grep -m 1 -o "textgrid-nonpublic" curl`
if [ -s $FILE -a "$URGL" = 'textgrid-nonpublic' ]; then
    echo -n "    $OK ["$VSTR
    echo -n $URGL
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    rm -f $FILE
    ERRORS=true
fi

#
# sesame public
#
FILE="curl"
SESAME=$SERVER"/1.0/triplestore?query=info"
echo "checking "$CSTR"sesame public"$CNRM $TRN $SESAME
curl -s $SESAME > $FILE
URGL=`grep -m 1 -o "textgrid-public" curl`
if [ -s $FILE -a "$URGL" = 'textgrid-public' ]; then
    echo -n "    $OK ["$VSTR
    echo -n $URGL
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    rm -f $FILE
    ERRORS=true
fi

#
# elasticsearch masternode
#
FILE="curl"
MASTERNODE=$SERVER":<%= @elasticsearch_master_http_port %>"
echo "checking "$CSTR"es masternode"$CNRM" (intern)"$TRN $MASTERNODE
curl -s $MASTERNODE > $FILE
URGL=`grep "200" curl`
if [ -s $FILE -a  "$URGL" = '  "status" : 200,' ]; then
    echo -n "    $OK ["$VSTR
    echo -n $URGL
    echo $CNRM"]"
    rm $FILE
else
    echo "    $FAILED"
    rm -f $FILE
    ERRORS=true
fi

#
# elasticsearch workhorse
#
FILE="curl"
WORKHORSE=$SERVER":<%= @elasticsearch_workhorse_http_port %>"
echo "checking "$CSTR"es workhorse"$CNRM" (intern)"$TRN $WORKHORSE
curl -s $WORKHORSE > $FILE
URGL=`grep "200" $FILE`
if [ -s $FILE ] && [ "$URGL" = '  "status" : 200,' ]; then
    echo -n "    $OK ["$VSTR
    echo -n $URGL
    echo $CNRM"]"
    rm $FILE
else
    echo "    $FAILED"
    rm -f $FILE
    ERRORS=true
fi

#
# fits core
#
FILE="/opt/dhrep/output"
FITS_VERSION=1.2.0
echo "checking "$CSTR"fits core"$CNRM" (intern)"$TRN
cd /home/tomcat-fits/fits-$FITS_VERSION
./fits.sh -i License.md -o $FILE
URGL=`grep toolname=\"FITS\" $FILE`
URGL=`echo ${URGL:85:5}`
if [ -s $FILE ] && [ "$URGL" = "$FITS_VERSION"  ] ; then
    echo -n "    $OK ["$VSTR
    echo -n $URGL
    rm $FILE
    rm fits.log
    echo $CNRM"]"
else
    echo "    $FAILED"
    rm -f $FILE
    rm -f fits.log
    ERRORS=true
fi

#
# fits service
#
FILE="version"
FITS=$SERVER":<%= @fits_port %>/fits/"$FILE
echo "checking "$CSTR"fits service"$CNRM" (intern)"$TRN $FITS
wget -q $FITS
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    cat $FILE | xargs echo -n
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    rm -f $FILE
    ERRORS=true
fi

#
# wildfly
#
# curl http://localhost:18080/jolokia/read/java.lang:type=Runtime/Uptime

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
    ERRORS=true
fi

#
# check for errors
#
if $ERRORS ; then
    echo "...service check $FAILED with exit code 2! Nagios --> FAILED/ERROR"
    exit 2
fi

echo "...service check turns out to be $OK"
exit 0
