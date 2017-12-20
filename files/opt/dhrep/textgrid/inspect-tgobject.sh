#!/bin/bash

case "$0" in
    /*)
        SCRIPTPATH=$(dirname "$0")
        ;;
    *)
        SCRIPTPATH=$(dirname "$PWD/$0")
        ;;
esac

# common config
DATA_PATH=/data/nonpublic/productive/pairtree_root/te/xt/gr/id
SESAME_URL=http://localhost:9091/openrdf-sesame/repositories/textgrid-nonpublic
ELASTICSEARCH_URL=http://localhost:9202/textgrid-nonpublic/metadata/
LDAP_URI=ldap://127.0.0.1:389
LDAP_PW=''

#######################################################################
# source configuration -> at least the LDAP PW
2>/dev/null source /etc/dhrep/consistency_check.conf
2>/dev/null source "${SCRIPTPATH}"/consistency_check.conf

# source common functions and settings
source "${SCRIPTPATH}"/functions.d/textgrid-shared.sh
source "${SCRIPTPATH}"/functions.d/inspect.sh

VERBOSE=0

function show_help {
    echo "usage: $0 textgridUri"
    echo "options:"
    echo "--verbose | -v    verbose"
    echo "--help    | -h    help (this message)"
    echo "--public  | -p    look in public repo (nonpublic is default)"
}

while :; do
    case $1 in
        -h|-\?|--help)
            show_help    # Display a usage synopsis.
            exit
            ;;
        -v|--verbose)
            VERBOSE=$((VERBOSE + 1))  # Each -v adds 1 to verbosity.
            ;;
        -p|--public)
            DATA_PATH=/data/public/productive/pairtree_root/te/xt/gr/id
            SESAME_URL=http://localhost:9091/openrdf-sesame/repositories/textgrid-public
            ELASTICSEARCH_URL=http://localhost:9202/textgrid-public/metadata/
            ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: No more options, so break out of the loop.
            break
    esac

    shift
done

# exit and show help if no uri given
if [ "$#" == "0" ]; then
    echo -e "\e[31mno textgridUri given\e[0m"
    show_help    # Display a usage synopsis.
    exit
fi

#### here the main programm starts

uri=$1

# split incoming param after : to remove the textgrid: prefix if there
id=${uri#*:}

path=$(id2path $id)

if [ -d $path ] ; then
    ok "${path} exists"
    #ls -alh $path/textgrid*
else 
   error "${path} does not exist in storage"
fi

isInLdap "textgrid:${id}"
LDAP_RESULT=$?

if [ "$LDAP_RESULT" -ne "0" ]; then
    error "$id not in rbac"
else
    ok "$id in rbac (public/nonpublic not differentiated in rbac)"
fi

isInSesame "textgrid:${id}"
SESAME_RESULT=$?

if [ "$SESAME_RESULT" -ne "0" ]; then
    error "$id not in sesame"
else
    ok "$id in sesame"
    if [ "$VERBOSE" -gt "0" ]; then
        sesameDump "textgrid:${id}"
    fi
fi

isInElasticsearch $id
ES_RESULT=$?

if [ "$ES_RESULT" -ne "0" ]; then
    error "$id not in ElasticSearch"
else
    ok "$id in ElasticSeach"
    if [ "$VERBOSE" -gt "0" ]; then
        elasticsearchDump "${id}"
    fi
fi

validateOnDiskMd5 $id

