#!/bin/bash

###
# VARS
###

HOST=$1;
DEST=$HOST"_cr_entries.xml";
TMP1=$HOST"_1.tmp";
TMP2=$HOST"_2.tmp";
TMP3=$HOST"_3.tmp";
TMP4=$HOST"_4.tmp";

###
# METHODS
###

# Delete temporary files
function delete_temp_files () {
    rm -f $TMP1
    rm -f $TMP2
    rm -f $TMP3
    rm -f $TMP4
}

###
# DO IT!
####
# DEPENDENCIES: You will need xmllint and jq for XML and JSON parsing!
###

if [ $1"x" == "x" ]; then
    echo "Please provide the host name: [repository|dhrepworkshop|trep].de.dariah.eu"
    echo "$0 [HOSTNAME]"
    exit 1;
fi

echo "---> HOSTNAME: $HOST";

delete_temp_files;

# Check for existing output file
if [ -f "$DEST" ]; then
    echo "---> ERROR! OUTPUT FILE ALREADY EXISTS: $DEST!"
    exit 1;
fi

echo "---> OUTPUT FILE: $DEST";

# 1. We need all collections from DH-rep visa OAI-PMH: <https://$HOST/1.0/oaipmh/oai?verb=ListSets>
echo -n "---> Getting all sets from OAI-PMH... ";
# listsets1.tmp: OAI-PMH ListSets response
curl -XGET -s "https://$HOST/1.0/oaipmh/oai?verb=ListSets" > $TMP1;
# listsets3.tmp: All Handle PIDs only
xmllint --xpath "//*[local-name()='setSpec']/text()" $TMP1 > $TMP2
declare -i SETS=$(wc -l < $TMP2)
echo "FOUND $SETS SETS";

# Loop collections
echo "---> Getting metadata for each set";
COUNT=0
while IFS= read -r PID; do
    let COUNT=COUNT+1
    echo -n "---> ($COUNT/$SETS) Processing $PID... ";
    # For each collection (OAI-PMH set), get record metadata: <https://$HOST/1.0/oaipmh/oai?verb=GetRecord&identifier=hdl:21.T11991/0000-001B-4E7C-2&metadataPrefix=oai_dc>
    echo -n "PASS#1... "
    # listsets4.tmp: Single OAI-PMH record
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
    # Get contributor from Handle metadata: <https://hdl.handle.net/api/handles/21.T11991/0000-001B-4E7C-2?type=RESPONSIBLE>
    echo -n "PASS#2... "
    # listsets5.tmp: JSON file from Handle server for each PID
    curl -XGET -s "https://hdl.handle.net/api/handles/21.T11991/0000-001B-4E7C-2?type=RESPONSIBLE" > $TMP4;
    CONTRIBUTOR="<dc:contributor>"$(jq .values[].data.value $TMP4)"</dc:contributor";
    CONTRIBUTOR=${CONTRIBUTOR/\"/}
    CONTRIBUTOR=${CONTRIBUTOR/\"/}
    # For each collection, build the CR request body from metadata. Write it to one file for Tobi (for the moment :-)
    echo "" >> $DEST;
    echo "<rdf:RDF xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">" >> $DEST;
    echo "  <rdf:Description rdf:about=\"$DOI_WITH_RESOLVER\">" >> $DEST;
    echo "        $IDENTIFIER_CR" >> $DEST;
    echo "        $CREATOR" >> $DEST;
    echo "        $RIGHTS" >> $DEST;
    echo "        $IDENTIFIER_HDL" >> $DEST;
    echo "        $FORMAT" >> $DEST;
    echo "        $CONTRIBUTOR" >> $DEST;
    echo "        $TITLE" >> $DEST;
    echo "        $IDENTIFIER_DOI" >> $DEST;
    echo "    </rdf:Description>" >> $DEST;
    echo "</rdf:RDF>" >> $DEST;
    echo "DONE";
    # TODO Later send it to <https://$HOST/colreg-ui/api/collections/submitAndPublish> automatically!
done < $TMP2

# TODO Get the Handle metadata SOURCE (ID used as redis key): <https://hdl.handle.net/api/handles/21.T11991/0000-001B-4E7C-2?type=SOURCE>

# TODO Get CRID from CR response

# TODO Add CRID to redis, you need the key (SOURCE ID from Handle metadata): "crid_https://de.dariah.eu/storage/EAEA0-1DDA-E710-7EC3-0" and the value (CRID from CR response): "611cc40f2437297ef712fe16"

delete_temp_files;
