#!/usr/bin/env bash

HOST="trep.de.dariah.eu";
echo "---> HOSTNAME: $HOST";

# 1. We need all collections from DH-rep visa OAI-PMH: <https://trep.de.dariah.eu/1.0/oaipmh/oai?verb=ListSets>
echo -n "---> Getting all sets from OAI-PMH... ";
curl -XGET -s "https://$HOST/1.0/oaipmh/oai?verb=ListSets" > listsets1.tmp;
less listsets1.tmp | grep "<setSpec>" > listsets2.tmp;
rm -f listsets3.tmp;
touch listsets3.tmp;
SETS=0;
while IFS= read -r LINE; do
    echo ${LINE:21:30} >> listsets3.tmp;
    let SETS=SETS+1;
done < listsets2.tmp;
echo "FOUND $SETS SETS";

# Loop collections
echo "---> Getting metadata for each set";
COUNT=0
rm -f cr_entries.txt
while IFS= read -r PID; do
    let COUNT=COUNT+1
    echo -n "    ---> Processing $PID ($COUNT/$SETS)... ";
    # For each collection (OAI-PMH set), get record metadata: <https://trep.de.dariah.eu/1.0/oaipmh/oai?verb=GetRecord&identifier=hdl:21.T11991/0000-001B-4E7C-2&metadataPrefix=oai_dc>
    echo -n "PASS#1:OAI-PMH... "
    curl -XGET -s "https://$HOST/1.0/oaipmh/oai?verb=GetRecord&identifier=$PID&metadataPrefix=oai_dc" > listsets4.tmp;
    IDENTIFIER_CR=$(xmllint --xpath "//*[local-name()='dc']/*[local-name()='identifier'][starts-with(text(),'hdl:')]" listsets4.tmp);
    IDENTIFIER_CR=${IDENTIFIER_CR/hdl:/};
    IDENTIFIER_CR=${IDENTIFIER_CR/\//%2F/};
    IDENTIFIER_CR=${IDENTIFIER_CR/identifier>/identifier>https:\/\/$HOST\/1.0\/oaipmh\/oai/};
    DOI_WITH_RESOLVER=$(xmllint --xpath "//*[local-name()='dc']/*[local-name()='identifier'][starts-with(text(),'doi:')]/text()" listsets4.tmp);
    DOI_WITH_RESOLVER=${DOI_WITH_RESOLVER/doi:/http://dx.doi.org/};
    CREATOR=$(xmllint --xpath "//*[local-name()='dc']/*[local-name()='creator']" listsets4.tmp);
    RIGHTS=$(xmllint --xpath "//*[local-name()='dc']/*[local-name()='rights']" listsets4.tmp);
    IDENTIFIER_HDL=$(xmllint --xpath "//*[local-name()='dc']/*[local-name()='identifier'][starts-with(text(),'hdl:')]" listsets4.tmp);
    FORMAT=$(xmllint --xpath "//*[local-name()='dc']/*[local-name()='format']" listsets4.tmp);
    TITLE=$(xmllint --xpath "//*[local-name()='dc']/*[local-name()='title']" listsets4.tmp);
    IDENTIFIER_DOI=$(xmllint --xpath "//*[local-name()='dc']/*[local-name()='identifier'][starts-with(text(),'doi:')]" listsets4.tmp);
    # Get contributor from Handle metadata: <https://hdl.handle.net/api/handles/21.T11991/0000-001B-4E7C-2?type=RESPONSIBLE>
    echo -n "PASS#2:HDL-MD... "
    curl -XGET -s "https://hdl.handle.net/api/handles/21.T11991/0000-001B-4E7C-2?type=RESPONSIBLE" > listsets5.tmp;
    CONTRIBUTOR="<dc:contributor>"$(jq .values[].data.value listsets5.tmp)"</dc:contributor";
    CONTRIBUTOR=${CONTRIBUTOR/\"/}
    CONTRIBUTOR=${CONTRIBUTOR/\"/}
    # For each collection, build the CR request body from metadata. Write it to one file for Tobi (for the moment :-)
    echo "" >> cr_entries.txt;
    echo "<rdf:RDF xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">" >> cr_entries.txt;
    echo "  <rdf:Description rdf:about=\"$DOI_WITH_RESOLVER\">" >> cr_entries.txt;
    echo "        $IDENTIFIER_CR" >> cr_entries.txt;
    echo "        $CREATOR" >> cr_entries.txt;
    echo "        $RIGHTS" >> cr_entries.txt;
    echo "        $IDENTIFIER_HDL" >> cr_entries.txt;
    echo "        $FORMAT" >> cr_entries.txt;
    echo "        $CONTRIBUTOR" >> cr_entries.txt;
    echo "        $TITLE" >> cr_entries.txt;
    echo "        $IDENTIFIER_DOI" >> cr_entries.txt;
    echo "    </rdf:Description>" >> cr_entries.txt;
    echo "</rdf:RDF>" >> cr_entries.txt;
    echo "DONE";
    # TODO Later send it to <https://trep.de.dariah.eu/colreg-ui/api/collections/submitAndPublish> automatically!
done < listsets3.tmp

# TODO Get the Handle metadata SOURCE (ID used as redis key): <https://hdl.handle.net/api/handles/21.T11991/0000-001B-4E7C-2?type=SOURCE>

# TODO Get CRID from CR response

# TODO Add CRID to redis, you need the key (SOURCE ID from Handle metadata): "crid_https://de.dariah.eu/storage/EAEA0-1DDA-E710-7EC3-0" and the value (CRID from CR response): "611cc40f2437297ef712fe16"

# Delete temporary files
rm listsets1.tmp
rm listsets2.tmp
rm listsets3.tmp
rm listsets4.tmp
rm listsets5.tmp
