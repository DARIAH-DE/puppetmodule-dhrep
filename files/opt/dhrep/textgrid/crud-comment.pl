#!/usr/bin/perl -w 

@a = gmtime (time - 60*60*24 ); 
$yesterday = sprintf ("%04d-%02d-%02d", $a[5]+1900, $a[4]+1, $a[3]); 
system "/opt/dhrep/crud-analyse-script.pl -l /var/log/dhrep/tgcrud/rollback.log.${yesterday} -c /var/log/dhrep/tgcrud/logcomments.${yesterday}.log";
system "/opt/dhrep/crud-analyse-script.pl -l /var/log/dhrep/tgcrud-public/rollback.log.${yesterday} -c /var/log/dhrep/tgcrud-public/logcomments.${yesterday}.log";
