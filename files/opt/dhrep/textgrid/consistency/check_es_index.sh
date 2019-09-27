#!/bin/bash

case "$0" in
    /*)
        SCRIPTPATH=$(dirname "$0")
        ;;
    *)
        SCRIPTPATH=$(dirname "$PWD/$0")
        ;;
esac

# find all elasticsearch entries where the internal id (._id) does not match the 
# id in json metadata (textgridUri without the 'textgrid:'-prefix).
function run_query {
  local JSON=`curl --request POST \
    --silent \
    --url http://localhost:9202/textgrid-nonpublic,textgrid-public/metadata/_search \
    --header 'content-type: application/json' \
    --data @- << EOF
      {
        "query": {
          "bool" : {
            "filter" : {
              "script" : {
                "script" : {
                  "lang": "painless",
                  "source": "
                    if(doc['baseUri.keyword'].length < 1) {
                      return true;
                    }
                    def base = doc['baseUri.keyword'][0].substring(9);
                    def rev = doc['revision'][0];
                    String uri = base + '.' + rev;
                    return uri != doc['_id'].value;
                  "
                }
              }
            }
          }
        },
        "_source": {
          "includes": ["textgridUri"]
        },
        "size": 30
      }
EOF`
  echo $JSON
}

function idsFromJSON {
  echo $1 | jq -r '.hits.hits[] | ._id'
}

case "$1" in
  nagios)
    # https://www.digitalocean.com/community/tutorials/how-to-create-nagios-plugins-with-bash-on-ubuntu-12-10
    JSON=$(run_query)
    HITS=`echo $JSON | jq .hits.total`
    if ((HITS > 0)); then
      # uncomment below for changing icinga status from warning to critical
      #echo "CRITICAL - found $HITS entries in elasticsearch where ID does not match textgridUri"
      #exit 2
      echo "WARNING - found $HITS entries in elasticsearch where ID does not match textgridUri"
      exit 1
    fi
    echo "OK - IDs and textgridUris in elasticsearch do all match"
    exit 0
    ;;
  hitsonly) 
    JSON=$(run_query)
    echo $JSON | jq .hits.total
    ;;
  all)
    JSON=$(run_query)
    echo $JSON | jq .
    ;;
  uris)
    JSON=$(run_query)
    echo `idsFromJSON $JSON`
    ;;
  hdcheck)
    echo -e "\e[34mWarning: this operation is just a quick hack and does only work for nonpublic data. use  ../inspect-tgobject.sh -p in that case\e[0m"
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
    echo "  nagios    - run as nagios check"
    echo "  all       - show elasticsearch response for query (limit in query is 30)"
    echo "  uris      - show only broken uris (limit in query is 30)"
    echo -e "  hdcheck   - for each broken uri test if it exists in storage \e[34m- Only for nonpublic data. FIXME\e[0m"
    echo "  hitsonly  - only print number of fund inconsistencies, e.g. for writing to file per cronjob for nagios"
    ;;
esac

