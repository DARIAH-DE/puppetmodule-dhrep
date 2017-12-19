#!/bin/bash
#
# common utility functions for examining and accessing textgrid repository data
#


#######################################################################
# function pairtreeFN
# generate pair tree paths
# $1 string that shall be transformed to pairtree path
function pairtreeFN {
    local OUT=""
    local LEN=${#1}
    local STEPS=$(($LEN / 2))
    for (( i = 0; i < $LEN; i+=2 ))
    do
        OUT=$OUT/${1:i:2}
    done;
    echo $OUT
}

#######################################################################
# function isInLdap
# requires global variable LDAP_URI and LDAP_PW to be set
# $1 textgridURI
function isInLdap {
    local CNT=$(ldapsearch -x -H $LDAP_URI -b ou=resources,ou=rbac,dc=textgrid,dc=de -D cn=rbac,ou=bindaccounts,dc=textgrid,dc=de -w $LDAP_PW "(TGResourceURI=$1)" dn | grep -c "dn:")
    # echo inLDAP $CNT $1
    if [ "$CNT" -ge "1" ]; then
        return 0
    else
    	  return 1
    fi
}

#######################################################################
# generate path for stornext
# requires global variable DATA_PATH to be set
# $1 textgrid-id (without the 'textgrid:' prefix)
function id2path {
    local id=$1
    # replace . with ,
    id=${id/./,}
    # add +
    id=+$id
    local pt=$(pairtreeFN $id)
    local path=${DATA_PATH}${pt}
    echo $path
}

#######################################################################
# function sesameDump
# print all information from sesame related to incoming textgridUri
# requires global variable SESAME_URL to be set
# $1 textgridURI
function sesameDump {
  local uri=$1
  
  curl -XPOST $SESAME_URL \
       --header 'Accept: application/rdf+turtle, */*;q=0.5' \
       --header 'Content-Type: application/x-www-form-urlencoded' \
       --silent \
       --data-urlencode "query=
          CONSTRUCT {
            <${uri}> ?p1 ?o1 .
            ?s2 ?p2 <${uri}> .
          } WHERE {
            <${uri}> ?p1 ?o1 .
            ?s2 ?p2 <${uri}> .
          }"


}

#######################################################################
# function isInSesame
# return 0 if uri is found in sesame 1 otherwise
# requires global variable SESAME_URL to be set
# $1 textgridURI
function isInSesame {
  local uri=$1
  
  local res=`curl -XPOST $SESAME_URL \
       --header 'Accept: text/boolean, */*;q=0.5' \
       --header 'Content-Type: application/x-www-form-urlencoded' \
       --silent \
       --data-urlencode "query=
          ASK {
            <${uri}> ?p1 ?o1 .
            ?s2 ?p2 <${uri}> .
          }"`

    if [ "$res" == "true" ]; then
        return 0
    else
    	  return 1
    fi

}

#######################################################################
# function elasticsearchDump
# dump the elasticsearch entry for id
# requires global variable ELASTICSEARCH_URL to be set
# $1 textgrid-id (without the 'textgrid:' prefix)
function elasticsearchDump {
    local id=$1

    curl --silent $ELASTICSEARCH_URL/$id | jq .
}

#######################################################################
# function isInElasticsearch
# return 0 if uri is found in elasticsearch 1 otherwise
# requires global variable ELASTICSEARCH_URL to be set
# $1 textgrid-id (without the 'textgrid:' prefix)
function isInElasticsearch {
    local id=$1

    local res=`curl --silent $ELASTICSEARCH_URL/$id | jq .found`

     if [ "$res" == "true" ]; then
        return 0
    else
    	  return 1
    fi 
}

