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
CRUD=$SERVER":<%= @crud_port %>/dhcrud-public/"$FILE
echo "checking "$CSTR"dhcrud"$CNRM" (intern)"$TRN $CRUD
curl -s $CRUD > $FILE
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    cat $FILE
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    rm $FILE
    ERRORS=true
fi

#
# dhcrud (public) don't worry, it is correct this way :-)
#
FILE="version"
CRUD=$SERVER":<%= @crud_port %>/dhcrud/"$FILE
echo "checking "$CSTR"dhcrud public"$CNRM $TRN $CRUD
curl -s $CRUD > $FILE
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    cat $FILE
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    rm $FILE
    ERRORS=true
fi

#
# dhpublish
#
FILE="version"
PUBLISH=$SERVER":<%= @publish_port %>/dhpublish/"$FILE
echo "checking "$CSTR"dhpublish"$CNRM $TRN $PUBLISH
curl -s $PUBLISH > $FILE
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    cat $FILE
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    rm $FILE
    ERRORS=true
fi

#
# publikator
#
FILE="publikator"
PUBLIKATOR=$SERVER"/"$FILE
echo "checking "$CSTR"publikator"$CNRM $TRN $PUBLIKATOR
curl -Lks $PUBLIKATOR > $FILE
URGL=`grep \<span\>DARIAH-DE $FILE`
URGL=`echo ${URGL:35:5}`
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    echo -n $URGL
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    rm $FILE
    ERRORS=true
fi

#
# oaipmh
#
FILE="version"
OAIPMH=$SERVER":<%= @oaipmh_port %>/oaipmh/oai/"$FILE
echo "checking "$CSTR"oaipmh"$CNRM $TRN $OAIPMH
curl -s $OAIPMH > $FILE
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    cat $FILE
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    rm $FILE
    ERRORS=true
fi

#
# pid
#
FILE="version"
PID=$SERVER":<%= @pid_port %>/dhpid/"$FILE
echo "checking "$CSTR"dhpid"$CNRM" (intern)"$TRN $PID
curl -s $PID > $FILE
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    cat $FILE
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    rm $FILE
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
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    rm $FILE
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
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    rm $FILE
    ERRORS=true
fi

#
# wildfly
#
FILE="wildfly"
WILDFLY=$SERVER":18080/jolokia/read/java.lang:type=Runtime/Uptime"
echo "checking "$CSTR"wildfly"$CNRM" (intern)"$TRN $WILDFLY
curl -s $WILDFLY > $FILE
URGL=`grep \"status\":200 $FILE`
URGL=`echo ${URGL: -13:12}`
if [ -s $FILE ] && [ "$URGL" = "\"status\":200"  ] ; then
    echo -n "    $OK ["$VSTR
    echo -n $URGL
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    rm $FILE
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
    rm $FILE
    rm fits.log
    ERRORS=true
fi

#
# fits service
#
FILE="version"
FITS=$SERVER":<%= @fits_port %>/fits/"$FILE
echo "checking "$CSTR"fits service"$CNRM" (intern)"$TRN $FITS
curl -s $FITS > $FILE
if [ -s $FILE ]; then
    echo -n "    $OK ["$VSTR
    cat $FILE | xargs echo -n
    rm $FILE
    echo $CNRM"]"
else
    echo "    $FAILED"
    rm $FILE
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
