#!/bin/bash
#
# functions for inspecting objects, which print stuff to stdout
# require textgrid-shared fuctions to be sources from calling script

# print a normal color ok string
function ok {
    local message=$1
    echo -e "[OK] $message"
}

# print a red error string
function error {
    local message=$1
    echo -e "\e[31m[ERROR] $message \e[0m"
}

# print a orange warning string
function warn {
    local message=$1
    echo -e "\e[33m[WARNING] $message \e[0m"
}

#######################################################################
# function validateOnDiskMd5
# get md5 from on disk metadata file and check with actual files md5
# $1 textgrid-id (without the 'textgrid:' prefix)
function validateOnDiskMd5 {
    local id=$1
    local path=$(id2path $id)
    local fileloc=${path}/textgrid+${id/./,}
    local metaloc=${path}/textgrid+${id/./,}.meta

    local filemd5=`md5sum $fileloc | cut -d " " -f1`
    local metamd5=`xqilla -i ${metaloc} <(echo "//*:fixity[*:messageDigestAlgorithm='md5']/*:messageDigest/text()")`

    if [ "$VERBOSE" -gt "0" ]; then
        echo "md5sum of file: ${filemd5}"
        echo "md5 in meta: ${metamd5}"
    fi

    if [ "${filemd5}" == "${metamd5}" ]; then
        ok "md5 in ondisk-metadata matches the file md5"

    elif [ "${metamd5}" == "" ]; then
        warn "no md5 in ondisk metadata"
    else 
        error "md5 in ondisk-metadata and the files md5 do not match"
    fi

}


