#!/bin/bash

SERVER="http://vm1/1.0"
#SERVER="http://textgridlab.org/1.0"

#
# tgauth
#
FILE="tgextra.wsdl"
AUTH=$SERVER"/tgauth/wsdl/"$FILE
echo "Checking TG-auch on "$AUTH
wget -q $AUTH
if [ -s $FILE ]; then
    rm $FILE
    echo "    $(tput setaf 2)TG-auth OK$(tput sgr0)"
else
    echo "    $(tput setaf 1)TG-auth FAILED!$(tput sgr0)"
fi

#
# tgauth pubic
#
FILE="tgextra-crud.wsdl"
AUTH=$SERVER"/tgauth/wsdl/"$FILE
echo "Checking TG-auth crud on "$AUTH
wget -q $AUTH
if [ -s $FILE ]; then
    rm $FILE
    echo "    $(tput setaf 2)TG-auth crud OK$(tput sgr0)"
else
    echo "    $(tput setaf 1)TG-auth crud FAILED!$(tput sgr0)"
fi
#
# tgcrud
#
FILE="version"
CRUD=$SERVER"/tgcrud/rest/"$FILE
echo "Checking TG-crud service on "$CRUD
wget -q $CRUD
if [ -s $FILE ]; then
    echo -n "    " 
    cat $FILE
    rm $FILE
    echo
    echo "    $(tput setaf 2)TG-crud OK$(tput sgr0)"
else
    echo "    $(tput setaf 1)TG-crud FAILED!$(tput sgr0)"
fi

#
# tgcrud public
#
FILE="version"
CRUD=$SERVER"/tgcrud-public/rest/"$FILE
echo "Checking TG-crud public service on "$CRUD
wget -q $CRUD
if [ -s $FILE ]; then
    echo -n "    " 
    cat $FILE
    rm $FILE
    echo
    echo "    $(tput setaf 2)TG-crud public OK$(tput sgr0)"
else
    echo "    $(tput setaf 1)TG-crud public FAILED!$(tput sgr0)"
fi

#
# tgsearch
#
FILE="search?q=fu"
SEARCH=$SERVER"/tgsearch/"$FILE
echo "Checking TG-search on "$SEARCH
wget -q $SEARCH
if [ -s $FILE ]; then
    rm $FILE
    echo "    $(tput setaf 2)TG-search OK$(tput sgr0)"
else
    echo "    $(tput setaf 1)TG-search FAILED!$(tput sgr0)"
fi

#
# tgsearch public
#
FILE="search?q=fu"
SEARCH=$SERVER"/tgsearch-public/"$FILE
echo "Checking TG-search public on "$SEARCH
wget -q $SEARCH
if [ -s $FILE ]; then
    rm $FILE
    echo "    $(tput setaf 2)TG-search public OK$(tput sgr0)"
else
    echo "    $(tput setaf 1)TG-search public FAILED!$(tput sgr0)"
fi

#
# aggregator
#

#
# tgpublish
#
FILE="version"
PUBLISH=$SERVER"/tgpublish/"$FILE
echo "Checking TG-publish on "$PUBLISH
wget -q $PUBLISH
if [ -s $FILE ]; then
    echo -n "    "
    cat $FILE
    rm $FILE
    echo
    echo "    $(tput setaf 2)TG-publish OK$(tput sgr0)"
else
    echo "    $(tput setaf 1)TG-publish FAILED!$(tput sgr0)"
fi

#
# tgoaipmh
#
FILE="oai?verb=Identify"
OAIPMH=$SERVER"/tgoaipmh/"$FILE
echo "Checking TG-oaipmh on "$OAIPMH
wget -q $OAIPMH
if [ -s $FILE ]; then
    rm $FILE
    echo "    $(tput setaf 2)TG-oaipmh OK$(tput sgr0)"
else
    echo "    $(tput setaf 1)TG-oaipmh FAILED!$(tput sgr0)"
fi

#
# tgpid
#
FILE="version"
OAIPMH=$SERVER"/tgpid/"$FILE
echo "Checking TG-pid on "$OAIPMH
wget -q $OAIPMH
if [ -s $FILE ]; then
    echo -n "    " 
    cat $FILE
    rm $FILE
    echo
    echo "    $(tput setaf 2)TG-pid OK$(tput sgr0)"
else
    echo "    $(tput setaf 1)TG-pid FAILED!$(tput sgr0)"
fi
