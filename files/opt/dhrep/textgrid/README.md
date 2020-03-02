# Scripts for repository maintenance

Located in the /opt/dhrep dir are some scripts for textgrid 
repository maintenance.

## check_ldap_backups.sh

## check_ldap_statistics.sh

## check_sesame_backups.sh

## crud-analyse.pl

## crud-comment.pl

## inspect-tgobject.sh

This script looks into different locations a textgrid-object is registered and prints its findings. 
The locations are

* Filesystem 
* LDAP
* Sesame Triplestore
* Elasticsearch

It also compares md5 checksums from metadata with md5 hash of file on disk.

Verbose output (-v) includes dumps of sesame statements, elaticsearch (this may 
be pretty long if fulltext included) and some extracted metadata like title and owner.

The default location of the script to check is the nonpublic area, if you want to check for 
public objects you need to use the command line flag -p.

The textgridUri may be written in its long form (textgrid:abc.0) or short (abc.0).

### Usage
`./inspect-tgobject.sh -h`             - show help
`./inspect-tgobject.sh <textgridUri>`  - show info about <textgridUri> in non public repository
`./inspect-tgobject.sh -p <textgridUri>`  - show info about <textgridUri> in public repository
`./inspect-tgobject.sh -v -p <textgridUri>`  - show verbose info about <textgridUri> in public repository

### Example

        $ ./inspect-tgobject.sh -p kv2q.0
        [OK] /data/public/productive/pairtree_root/te/xt/gr/id/+k/v2/q,/0 exists
        [OK] kv2q.0 in rbac (public/nonpublic not differentiated in rbac)
        [OK] kv2q.0 in sesame
        [OK] kv2q.0 in ElasticSeach
        [WARNING] no md5 in ondisk metadata 

## ldap-backup.sh

## sesame-backup.sh


## consistency

Consistency checks should end up in /opt/dhrep/consistency. This should be scripts which could be run
by nagios or by hand, frequently or just once a year to inform if the data is still healthy in all the indexes
like:

* filesystem (e.g. md5 checksums)
* LDAP
* triplestore
* elasticsearch
* PID-registry

### check_es_index.sh

Checks if there are totally broken entries in elasticsearch. It finds entries in textgrid-public or textgrid-nonpublic index
which habe no textgridUri in its metadata. This script is run by a cronjob installed by puppet in root's crontab:

        3 1 * * * /opt/dhrep/consistency/check_es_index.sh ids2file > /dev/null 2>&1

this cronjob logs faulty entries into a file `/opt/dhrep/consistency/esindex_broken_ids.log`. nagios checks if this file has 
entries with 

        /opt/dhrep/consistency/check_es_index.sh nagios

and reports a warning if this is the case. 

**TODO:** it seems like the used query is fast enough in elasticsearch6 to be executed in realtime, so the splitting of execution
in nagios and cronjob could possibly be removed to just use a real-time nagios query in future.




