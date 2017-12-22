#!/bin/bash

case "$0" in
    /*)
        SCRIPTPATH=$(dirname "$0")
        ;;
    *)
        SCRIPTPATH=$(dirname "$PWD/$0")
        ;;
esac

ID_FILE="${SCRIPTPATH}esindex_broken_ids.log"

# find all elasticsearch entries where the internal id (._id) does not match the 
# id in json metadata (textgridUri without the 'textgrid:'-prefix).
# needs the idMatchesTextgridUri.groovy script in elasticsearch script dir.
function run_query {
  local JSON=`curl --request POST \
    --silent \
    --url http://localhost:9202/_search \
    --header 'content-type: application/json' \
    --data '{
    "query": {
      "filtered" : {
        "query" : {
          "match_all": {}
        },
        "filter" : {
          "script" : {
            "lang": "groovy",
            "script_file": "idMatchesTextgridUri"
          }
        }
      }
    },
    "from": 0,
    "size": 30,
    "fields": ["textgridUri"]
  }'`
  echo $JSON
}

function idsFromJSON {
  echo $1 | jq -r '.hits.hits[] | ._id'
}

case "$1" in
  ids2file)
    rm $ID_FILE
    JSON=$(run_query)
    for uri in $(idsFromJSON $JSON); do
      echo $uri >> $ID_FILE
    done
  ;;
# old stuff
  hitsonly) 
    JSON=$(run_query)
    echo $JSON| jq .hits.total
    ;;
  nagios)
    JSON=$(run_query)
    # https://www.digitalocean.com/community/tutorials/how-to-create-nagios-plugins-with-bash-on-ubuntu-12-10
    HITS=`echo $JSON| jq .hits.total`
    if ((HITS > 0)); then
      echo "CRITICAL - found $HITS entries in elasticsearch where ID does not match textgridUri"
      exit 2
    fi
    echo "OK - IDs and textgridUris in elasticsearch do all match"
      exit 0
    ;;
  all)
    echo "NOTE: this script may need 5 minutes or more to finish."
    JSON=$(run_query)
    echo $JSON | jq .
    ;;
  uris)
    JSON=$(run_query)
    echo $(idsFromJSON $JSON)
    ;;
  hdcheck)
    JSON=$(run_query)
    for uri in $(idsFromJSON $JSON); do
      echo "${uri} has no / wrong metadata in elasticsearch"
      ../inspect-tgobject.sh $uri
      echo "---"
    done
    ;;
  *)
    echo -e "\e[31mNo command given.\e[0m" 
    echo "Usage: ${0} COMMAND"
    echo "Possible COMMANDs:"
    echo "  ids2file  - generate list of broken ids and save to ${ID_FILE} - recommended to use this command for further analysis and nagios"
    echo "Slow commands:"
    echo "  all       - show elasticsearch response for query (limit in query is 30)"
    echo "  uris      - show only broken uris (limit in query is 30)"
    echo "  hdcheck   - for each broken uri test if it exists in storage"
    echo "  nagios    - run as nagios check"
    echo "  hitsonly  - only print number of fund inconsistencies, e.g. for writing to file per cronjob for nagios"
    ;;
esac

