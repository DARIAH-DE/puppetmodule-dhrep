#!/bin/bash

###
# VARS
###

HOST=$1;
DEST=$HOST"_cr_entries.xml";
HANDLE_URL="hdl.handle.net";
MAP=$HOST"_cr_map.txt";
TMP1=$HOST"_1.tmp";
TMP2=$HOST"_2.tmp";
TMP3=$HOST"_3.tmp";
TMP4=$HOST"_4.tmp";
TMP5=$HOST"_5.tmp";
TMP6=$HOST"_6.tmp";

###
# METHODS
###

# Delete temporary files
function delete_temp_files () {
    rm -f $TMP1, $TMP2, $TMP3, $TMP4, $TMP5, $TMP6;
}

###
# DO IT!
####
# DEPENDENCIES: You will need xmllint and jq for XML and JSON parsing!
###

# Check for host parameter
if [ $1"x" == "x" ]; then
    echo "---> ERROR! Please provide host name parameter: [repository|dhrepworkshop|trep].de.dariah.eu"
    exit 1;
fi

echo "---> HOSTNAME: $HOST";

delete_temp_files;

# Check for existing output and mapping file
if [ -f "$DEST" ]; then
    echo "---> ERROR! Output file already exists: $DEST!"
    exit 1;
fi
if [ -f "$MAP" ]; then
    echo "---> ERROR! Mapping file already exists: $MAP!"
    exit 1;
fi

echo "---> OUTPUT FILE: $DEST";

# 1. We need all collections from DH-rep visa OAI-PMH: <https://$HOST/1.0/oaipmh/oai?verb=ListSets>
echo -n "---> Getting all sets from OAI-PMH... ";
# $TMP1: OAI-PMH ListSets response
curl -XGET -s "https://$HOST/1.0/oaipmh/oai?verb=ListSets" > $TMP1;
# $TMP2: All Handle PIDs only
xmllint --xpath "//*[local-name()='setSpec']/text()" $TMP1 > $TMP2
declare -i SETS=$(wc -l < $TMP2)
echo "FOUND $SETS SETS";

# Loop collections
echo "---> Getting metadata for each set";
COUNT=0
while IFS= read -r PID; do
    let COUNT=COUNT+1
    echo "---> ($COUNT/$SETS) Processing $PID";
    # Strip hdl:
    PID=${PID/hdl:/};
    # For each collection (OAI-PMH set), get record metadata: <https://$HOST/1.0/oaipmh/oai?verb=GetRecord&identifier=hdl:21.T11991/0000-001B-4E7C-2&metadataPrefix=oai_dc>
    echo -n "    ---> PASS#1: Get OAI-PMH metadata... "
    # $TMP3: Single OAI-PMH record
    curl -XGET -s "https://$HOST/1.0/oaipmh/oai?verb=GetRecord&identifier=$PID&metadataPrefix=oai_dc" > $TMP3;
    IDENTIFIER_CR=$(xmllint --xpath "//*[local-name()='dc']/*[local-name()='identifier'][starts-with(text(),'hdl:')]" $TMP3);
    IDENTIFIER_CR=${IDENTIFIER_CR/hdl:/};
    IDENTIFIER_CR=${IDENTIFIER_CR/\//%2F/};
    IDENTIFIER_CR=${IDENTIFIER_CR/identifier>/identifier>https:\/\/$HOST\/1.0\/oaipmh\/oai/};
    DOI_WITH_RESOLVER=$(xmllint --xpath "//*[local-name()='dc']/*[local-name()='identifier'][starts-with(text(),'doi:')]/text()" $TMP3);
    DOI_WITH_RESOLVER=${DOI_WITH_RESOLVER/doi:/http://dx.doi.org/};
    CREATOR=$(xmllint --xpath "//*[local-name()='dc']/*[local-name()='creator']" $TMP3);
    RIGHTS=$(xmllint --xpath "//*[local-name()='dc']/*[local-name()='rights']" $TMP3);
    IDENTIFIER_HDL=$(xmllint --xpath "//*[local-name()='dc']/*[local-name()='identifier'][starts-with(text(),'hdl:')]" $TMP3);
    FORMAT=$(xmllint --xpath "//*[local-name()='dc']/*[local-name()='format']" $TMP3);
    TITLE=$(xmllint --xpath "//*[local-name()='dc']/*[local-name()='title']" $TMP3);
    IDENTIFIER_DOI=$(xmllint --xpath "//*[local-name()='dc']/*[local-name()='identifier'][starts-with(text(),'doi:')]" $TMP3);
    echo "DONE";

    # Get contributor from Handle metadata: <https://hdl.handle.net/api/handles/21.T11991/0000-001B-4E7C-2?type=RESPONSIBLE>
    echo -n "    ---> PASS#2: Get Handle metadata... "
    # $TMP4: JSON file from Handle server for each PID
    curl -XGET -s "https://$HANDLE_URL/api/handles/$PID?type=RESPONSIBLE" > $TMP4;
    CONTRIBUTOR="<dc:contributor>"$(jq .values[].data.value $TMP4)"</dc:contributor";
    CONTRIBUTOR=${CONTRIBUTOR/\"/}
    CONTRIBUTOR=${CONTRIBUTOR/\"/}
    echo "DONE";

    # For each collection, build the CR request body from metadata. Also write it to DEST file.
    echo -n "    ---> PASS#3: Create and write CR submission info... ";
    # $TMP5: Information for CR submission
    echo "" > $TMP5;
    echo "<rdf:RDF xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">" >> $TMP5;
    echo "  <rdf:Description rdf:about=\"$DOI_WITH_RESOLVER\">" >> $TMP5;
    echo "        $IDENTIFIER_CR" >> $TMP5;
    echo "        $CREATOR" >> $TMP5;
    echo "        $RIGHTS" >> $TMP5;
    echo "        $IDENTIFIER_HDL" >> $TMP5;
    echo "        $FORMAT" >> $TMP5;
#    echo "        $CONTRIBUTOR" >> $TMP5;
    echo "        <dc:contributor>StefanFunk@dariah.eu</dc:contributor>" >> $TMP5;
    echo "        $TITLE" >> $TMP5;
    echo "        $IDENTIFIER_DOI" >> $TMP5;
    echo "    </rdf:Description>" >> $TMP5;
    echo "</rdf:RDF>" >> $TMP5;
    cat $TMP5 >> $DEST;
    echo "DONE";

    # Send it to <https://$HOST/colreg-ui/api/collections/submitAndPublish> automatically!
    echo -n "    ---> PASS#4: Call CR#submitAndPublish() for collection creation... ";
    if [ "$2" = "CR" ]; then
        curl -XPOST -s "https://$HOST/colreg-ui/api/collections/submitDraft/" -H 'Content-Type: application/xml' -d @$TMP5 > $TMP6;
        CRID=$(xmllint --xpath "//*[local-name()='collectionId']/text()" $TMP6);
        echo "$PID $CRID" >> $MAP;
        echo "DONE";
    else
        echo "SKIPPED";
    fi

    exit 2;

done < $TMP2

# TODO Get the Handle metadata SOURCE (ID used as redis key): <https://hdl.handle.net/api/handles/21.T11991/0000-001B-4E7C-2?type=SOURCE>

# TODO Get CRID from CR response

# TODO Add CRID to redis, you need the key (SOURCE ID from Handle metadata): "crid_https://de.dariah.eu/storage/EAEA0-1DDA-E710-7EC3-0" and the value (CRID from CR response): "611cc40f2437297ef712fe16"

delete_temp_files;
