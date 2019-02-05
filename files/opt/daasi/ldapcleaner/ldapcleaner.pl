#!/usr/bin/perl 
#
# ldapcleaner.pl
# This Skript 
# * either searches and replaces strings in a LDAP-Attribute
# * or deletes entries which have a certain value in an attribute
# 
# Author: Peter Gietz, DAASI International GmbH, www.daasi.de
# For questions please mail to peter.gietz@daasi.de
# Copyright: DAASI International GmbH 2012. All rights reserved.
#  
#  
# Version $Revision: 5851 $
# Last revision $Date: 2017-12-07 12:14:10 +0100 (Thu, 07 Dec 2017) $
# Last modified $LastChangedDate: 2017-12-07 12:14:10 +0100 (Thu, 07 Dec 2017) $
# Modifiedby $LastChangedBy: martin.haase $
# Filesource $URL: https://development.daasi.de:5443/svn/ldapcleaner/trunk/ldapcleaner.pl $
#
# Changelog ###############
# 2014-05-22 MH introduced feature "\#otherattr" in addstring in order to 
#               copy the value of another attribute to the attribute 
#               without needing a function call
# 2014-05-22 MH Allow for changing the RDN if the searchattribute gets a new value 
#               from replacestring and that attribute formed the RDN (in "Normal run")
# 2014-05-28 MH Pass Array Ref to Functions for multivalues ($param = \@paramvalues)
# 2014-07-24 MH respect a regexp replacement also if there is a filter given
# 2015-02-09 MH 2 bugs in isAdder: /^dn$/, not /dn/; pass '' instead of []
# 2015-03-12 MH new features postfilterfunction (-z) and needoperational (-o)
# 2015-04-15 MH adjusted maxentries if postfilterfunction is set (->sizelimit 0)
#               coded RDN change for isadder as well
#               introduced casesensitivecomparisonattributes (-b)
# 2015-05-19 MH new config param functionlibpath (no shorttag);
#               set $DAASIlib::Convert::ldap, $DAASIlib::Convert::rh_ldapserver
#               (use via 'our ($ldap,$rh_ldapserver)' in customer lib)
# 2015-05-20 MH introduced param basedn/-B for selecting an alternative basedn
#               fix in iscleaner: do not add empty strings to @newvals
# 2016-08-03 PG set $DAASIlib::Convert::conf to make configuration available in customer lib
# 2016-12-19 MH added dynamic self-call with the entries found to be used as
#               baseDNs (-B). New param dynamiccleanerinvocation (shorttag -X)
# 2017-03-08 MH added csvfields and csvoutputfile
# 2017-04-13 MH added multiple timefilter support (if -> while)
# 2017-06-22 MH use double backslash to escape ;s in addstring values
# 2017-07-13 MH Fixed bug: if filter (e.g. because of an ill-formatted time
#               string) is empty, did match *all* entries! Now: (undef=undef).
# 2017-09-26 MH createnewentry: := now means that the attr value is b64 encoded
#               new config param searchscope (no shorttag) {base|one|sub|children}
# 2017-10-02 MH inherited -T at dynamiccleanerinvocation
# 2017-10-26 MH added deleteonempty (no shorttag)
# 2017-12-07 MH added forcereplace (no shorttag), give multiple for #otherattr
#

use strict;
use warnings;

BEGIN {
    unshift @INC, './lib';
}

use MIME::Base64;
use File::Copy;
#use utf8;

#$| = 1;

use DAASIlib::CONF;
use DAASIlib::LOG;
use DAASIlib::Convert;
use DAASIlib::LDAP;
use DAASIlib::Data;
#use DAASIlib::SMTP;


our $data = new DAASIlib::Data;
my ($progname, $progpath, $etcdir, $sysconfig) = 
    $data->getProgramFiles($0,'./');
my $conf = new DAASIlib::CONF;

#$conf->loadConfig($sysconfig, $progpath, $etcdir);
my $gt = $conf->loadConfig($sysconfig, $progpath, $etcdir, 0, $progname);

my %config = %{$conf->{data}};

{ 
    ### make the config available in customer lib
    no warnings 'once';
    $DAASIlib::Convert::conf = $conf;
}

$data->init($progname, $conf->{data}{passwordfile});

my $log = new DAASIlib::LOG;
my $logger = $log->initLog4Perl($config{logfile},
				$config{loglevel}, $config{verbose} );

#print ( "############  ldapcleaner starting ############\n");
$logger->info ( "############  ldapcleaner starting ############" );
print ( "   Logging into $config{logfile} (level $config{loglevel})\n\n");

my $pidfile = $conf->{data}{pidfile};

if ( $pidfile ne 'NONE' ) {
    if ( -e $pidfile ) {
	$logger->error("#### found pid-file ($pidfile), brother is running I will terminate");
	my $pid = $data->getpid($pidfile);
	print  "   $0 is already running (pid $pid in file $pidfile) thus terminating this instance ...\n";
	goto ENDWITHOUT;
	
    }
    else {
	if ( ! open PIDFH, ">$pidfile" ) {
	    $logger->error("#### Couldn't open pid file $pidfile");
	    die "Couldn't open pid file\n";
	}
	print PIDFH $$;
	close PIDFH;
    }
}

my $conv = new DAASIlib::Convert;

if ( $conf->{data}{functionlib} ) {
   
    my $libpath = $conf->{data}{functionlibpath};

    if ($libpath && -d $libpath) {
	unshift @INC , $libpath; # "use lib" is evaluated at compile time
    }
    foreach my $module ( split /; ?/, $conf->{data}{functionlib} ) {
	eval ( "use $module;");
	if ( $@ ) {
	    $logger->warn("Couldn't load module $module:  $@");
	} else {
	    $logger->info("Loaded module $module");
	} 
    }

}



my $libldap = new DAASIlib::LDAP;

my ($in_header, $in_format, $in_sep, $in_quote ) = 
    &extractFormatstring($conf->{data}{inform}, "in");
my ($fpin, $rh_ldapserver, $sizelimit);

if ( $in_format =~ /LDIF/ ) {

#    $fpin = $libldap->initLdifFile($conf->{data}{inputfile},"r");
    $logger->error( "   Mode LDIF not yet implemented!");
    goto END;
}
elsif ($in_format =~ /LDAP/) {
    if ( $conf->{data}{maxentries} && !$conf->{data}{postfilterfunction} ) {
	$sizelimit = $conf->{data}{maxentries};
    } else {
	$sizelimit = 0;
    }

    $rh_ldapserver = $libldap->defineServerFromURI($conf->{data}{ldapuri},
					      'ldapuri', $sizelimit);

    my $alternativebasedn =  $conf->{data}{basedn};
    if ($alternativebasedn) {
	$rh_ldapserver->{basedn} = $alternativebasedn;
    }
    my $alternativesearchscope =  $conf->{data}{searchscope};
    if ($alternativesearchscope && $alternativesearchscope =~ /base|one|sub|children/) {
	$rh_ldapserver->{scope} = $alternativesearchscope;
    }
    
    { 
	### make the LDAP connection available in customer lib
	no warnings 'once';
	$DAASIlib::Convert::rh_ldapserver = $rh_ldapserver;
    }
    my $attr = $conf->{data}{searchattribute};

    if ( $attr && ($attr eq 'ALL' || $attr eq '*')  ) {
	if ( -e $conf->{data}{attributefile} ) {
	    $attr = &loadattributesfromfile($conf->{data}{attributefile});
	}
	else {
	    $attr='*';
	}
    }

    my $findstring = $conf->{data}{findstring};
    my $cleanerstring = $conf->{data}{cleanerstring};
    my $replacestring = $conf->{data}{replacestring};
    my $addstring = $conf->{data}{addstring}; 
    my $modifier = $conf->{data}{modifier};
    my $istest = $conf->{data}{testmode};
    my $newparentdn = $conf->{data}{transfertonewparent};
    my $wouldbe = $istest ? 'would be ' : '! ';
    my $createnewentry = $conf->{data}{createnewentry};
    my $needoperational = $conf->{data}{needoperational};
    my $casesensitives = $conf->{data}{casesensitivecomparisonattributes} || '';
    my @casesensitiveattrs = split ";", $casesensitives;
    my $dynamiccleanerskript =  $conf->{data}{dynamiccleanerinvocation};
    my $csvfieldsstring = $conf->{data}{csvfields};
    my $deleteonempty = $conf->{data}{deleteonempty}; # delete attr if func returns empty
    my $forcereplace = $conf->{data}{forcereplace}; # force replacement of attribute values even if the same values exist already

    my $iscsvoutput = $csvfieldsstring ? 1 : 0;
    my $isdelete = 0;
    my $iscleaner = 0;
    my $isleavecleaner = 0;
    my $isadder = $addstring ? 1 : 0;
    my $ismove = $newparentdn ? 1 : 0;
    my $isnewentry = $createnewentry ? 1 : 0;
    my $isinvocation = $dynamiccleanerskript ? 1 : 0;

#    print "find: $findstring\n";
#    print "replace: $replacestring\n";
#    print "modifier: $modifier\n";

    my $filter;
    my $isregexp = 0;
    my $code='';
    
    ### introduce simple/complex filter replacements for OLDER_THAN
    if ( $conf->{data}{searchfilter}) {
	$filter = $conf->{data}{searchfilter};
    } elsif ($conf->{data}{deletefilter} ) {
	$filter = $conf->{data}{deletefilter};
	$isdelete = 1;
    }

    ### CSV file output
    my @csvheadings;
    my @csvattributes;
    if ($iscsvoutput) {

	my $csvfilename = $conf->{data}{csvoutputfile};
	$logger->info("Writing entries to CSV file $csvfilename");
	open CSV, ">$csvfilename" unless $istest;
	my $first = 1;
	foreach my $field (split ';', $csvfieldsstring) {
	    print CSV ';' unless $first || $istest; # first CSV line with the headings
	    $first = 0;
	    if ($field =~ /([^:]+):([^:]+)/) {
		push @csvheadings, $1;
		$field = $2;
		print CSV "\"$1\"" unless $istest;  # first CSV line with the headings
	    } else {
		push @csvheadings, $field;
		print CSV "\"$field\"" unless $istest;
	    }
	    if ($field =~ /^(entrydn|(grand)*parentdn)$/ ) {
		my %map = ('entrydn' => 0,
			   'parentdn' => 1,
			   'grandparentdn' => 2,
			   'grandgrandparentdn' => 3,
			   'grandgrandgrandparentdn' => 4,
		    );
		my $index = $map{$field};
		$field = "dn:$index";
	    }
	    push @csvattributes, $field;
	}
	print CSV "\n" unless $istest; # now the first CSV line with the headings is finished
	$logger->info("Using CSV headers: |@csvheadings| for attributes: |@csvattributes|");
    }

    if ( $conf->{data}{regexp} ) {
	$logger->info("regexp: |".$conf->{data}{regexp}."|");
	$filter = $libldap->regexp2ldapfilter($findstring,$attr) unless ( $filter);
	
	my @findstrings =  split /\#;/, $findstring;	    
	my @replacestrings =  split /\#;/, $replacestring;	    

	foreach my $i ( 0..$#findstrings ) {

	    my $findstr = $findstrings[$i];    
	    my $replacestr = $replacestrings[$i];
 
		$code .= '$val =~ s/'.$findstr.'/'
		    .$replacestr.'/'.$modifier.'; ';
	}

	$logger->debug( "code: |$code|");
	$isregexp = 1;
    } # end if ( $conf->{data}{regexp} ) {

    my $isattributefilter = undef;

    if ($filter) {
#	print "\n*** found deletefilter\n\n";

	### timefilter comparison legend: 
	#### attributeOLDER_THAN123smhDMY
	#### attributeNEWER_THAN-123smhDMY (note the minus sign for NEWER)
	while ( $filter =~ 
	     /^\(?([^()]+?)\s?([A-Z]+_THAN)\s?([^()]+)\)?$/ ) {
##                 $1          $2              $3  
#	    print "\n*** found simple deletefilter\n\n";
	    $filter = $libldap->createldaptimefilter($2,$1,$3);
#	    print "Changed simple filter to: |$filter|\n";
	    $logger->debug("Changed simple filter to: |$filter|");
	}
	while ( $filter =~ 
		/^(.+?)\(([^()]+?)\s?([A-Z]+_THAN)\s?([^()]+)\)(.+?)$/ ){
##                 $1     $2      $3              $4    $5  
#	    print "\n*** found complex deletefilter\n\n";

	    my $firstpart=$1;
	    my $lastpart=$5;
	    my $timefilter = $libldap->createldaptimefilter($3,$2,$4);

	    $filter =$firstpart.$timefilter.$lastpart;
#	    print "Changed complex filter to: |$filter|\n";
	    $logger->debug("Changed complex filter is to: |$filter|");
	} 

	if ( 0 ) {
	    ### schauen ob ein Prozentpaar vorkommt, 
            ### dann den Filter generalisieren und den alten filter merken
	    $isattributefilter = 1;
	}
    } 
    elsif (  $cleanerstring ) {
	if ( $cleanerstring =~ /^(\+)(.+)/ ) {
	   $cleanerstring = $2;
	   $isleavecleaner = 1;
	}
	$filter = $libldap->regexp2ldapfilter($cleanerstring,$attr);
	$iscleaner = 1;
    } # end  elsif (  $cleanerstring ) {
    elsif ( $attr )  {
	if ( $conf->{data}{match} eq "eq" ) {
	    $filter = "($attr=".$findstring.")";
	}
	else {
	    $filter = "($attr=*".$findstring."*)";
	}
    }# end  elsif ( $attr )  {


    if ( $filter ) {
	$rh_ldapserver->{filter} = $filter;
    }
    elsif ( $isadder ) {
### this is dangerous and would change entries involuntarily
#	$filter = "(objectclass=*)";
	$filter='(undef=undef)';
#	print "   searching with filter: |$filter| isregexp: $isregexp\n";
	$rh_ldapserver->{filter} = $filter;
    }	
    else {	
	$logger->error("### ERROR: no filter (|$filter|) defined!");
	goto END;
    }
    $logger->info("searching with filter: |$filter| isregexp: $isregexp");


    my @attrs;
    if ( $attr ) {
	@attrs = split /;/, $attr;
    }
    
    if ($isdelete && $attr) {
	$rh_ldapserver->{attribs} = [ $attr ];
    }
    else {
	$rh_ldapserver->{attribs} = \@attrs;
    }

    if ( $needoperational ) {
	push @{$rh_ldapserver->{attribs}}, ('*','+');
    }


#   use Data::Dumper;
#   print Dumper($rh_ldapserver);
#   exit();

    my $ldap = $libldap->connectServer($rh_ldapserver);

    { 
	### make the LDAP connection available in customer lib
	no warnings 'once';
	$DAASIlib::Convert::ldap = $ldap;
    }

    if ( ! $ldap ) {
	$logger->error( "   couldn't connect to LDAP server ".
	    $conf->{data}{ldapuri});
	goto END;
    }

#######
####### Searching for entries starts here
#######
    my $mesg = $libldap->doSearch($ldap, $rh_ldapserver);

    $libldap->logLDAPError($mesg, "search", 0);


    my $deletecount = 0;

    my @entries = $mesg->entries();
    my $max = scalar @entries;
    $logger->info("Found $max entries");

    my $postfilterfunction = $conf->{data}{postfilterfunction};
    if ( $postfilterfunction ) {
	my $maxcount = 0;
	if ( $conf->{data}{maxentries} ) {
	    $maxcount = $conf->{data}{maxentries};
	}
	my @resultset = ();
	my $i = 0;
	for my $entry ( @entries ) {
	    my $dn = $entry->dn();
	    my $include = $conv->$postfilterfunction($entry);
	    if ($include) {
		push @resultset, $entry;
		$i++;
		$logger->debug("main(): $dn passed filter function $postfilterfunction");
	    } else {
		$logger->debug("main(): $dn did NOT pass filter function $postfilterfunction");
	    }
	    last if $maxcount != 0 && $i >= $maxcount;
	}
	@entries = @resultset;
	$max = scalar @entries;
	$logger->info("After filtering: $max entries remaining");
    }
    elsif ( $isattributefilter )  {

    }

#######
####### @entry processing starts here
#######
    if ( $isinvocation ) {
	my @dynamiccleanerskripts = split ";", $dynamiccleanerskript;
	$logger->info($wouldbe."invoking config skript(s) $dynamiccleanerskript for all entries matching the filter: $filter");
	foreach my $entry ( @entries ) {
	    foreach my $script ( @dynamiccleanerskripts ) {
		### e.g. "-B /path/some-ldapcleanerconfig.conf"
		if ($script =~ /^-B (.+)$/) { ### invoke using dynamic basedn
		    my $config = $1;
		    my $entrydn = $entry->dn();
		    $logger->info( $wouldbe."invoking ldapcleaner $0 with config $config for base $entrydn" );
		    # TODO check dynamiccleanerskript contains no -B / basedn
		    if ( $config =~ /'/ || $entrydn =~ /'/ ) {
			# safeguarding shell command
			$logger->error( "config or base contains an apostrophe ('), cannot invoke child, please invoke it manually" );
			next;
		    }
		    if 	( $istest ) {
			my $result = system "$0 -c '$config' -T -B '$entrydn'";
			$logger->info( "result: $result" );
		    } else {
			my $result = system "$0 -c '$config' -B '$entrydn'";
			$logger->info( "result: $result" );
		    }
		}
	    }
	}
    }
    elsif ( $iscsvoutput ) {
	$logger->info($wouldbe."Dumping all entries with attributes |@csvattributes| to CSV file ". $conf->{data}{csvoutputfile});
	foreach my $entry ( @entries ) {
	    $logger->info( $wouldbe."Dumping entry ".$entry->dn() );
	    my $first = 1;
	    foreach my $attr (@csvattributes) {
		print CSV ';' unless $first || $istest; 
		$first = 0;
		my $value;
		if ($attr =~ /^dn:(\d)$/ ) {
		    my $cut_by_index = $1;
		    $value = $libldap->cut_dn($entry->dn(),$cut_by_index);
		} else {
		    my @values = $entry->get_value ( $attr );
		    $value = join '|', @values;
		}
		$value =~ s/"/\\"/g;
		print CSV "\"$value\"" unless $istest;
	    }
	    print CSV "\n" unless $istest;
	}
    }
    elsif ( $ismove ) {
	$logger->info($wouldbe."Moving all entries matching the filter: $filter to new parent $newparentdn");
	foreach my $entry ( @entries ) {
	    $logger->info( $wouldbe."Moving entry ".$entry->dn() );
	    if 	(! $istest ) {
		my $ret = $libldap->moveDn($ldap,$entry->dn(),$newparentdn,0);
		if ($ret) {
		    $logger->info("...Success.");
		} else {
		    $logger->error("...Move failed for DN ".$entry->dn());
		}
	    }
	}
    }
    elsif ( $isdelete ) {
	$logger->info($wouldbe."Deleting all entries matching the filter: $filter");
	foreach my $entry ( @entries ) {
	    $logger->info( $wouldbe."Deleting entry ".$entry->dn() );
	    if ( $attr ) {

#		foreach my $attr ( $entry->attributes ) {
#		    print join( "\n ", $attr, $entry->get_value( $attr ) ), "\n";
#		}
		my $val = $entry->get_value($attr);
		$logger->info("$attr: $val") if $val;
	    }
	    my $oldentry = $entry->clone();
	    my $deletedentry;
	    if ($conf->{data}{createdeletedentry} ) {
		$deletedentry = createdeletedentry($oldentry, 
						   $conf->{data}{createdeletedentry} );
		$logger->info( $wouldbe."Adding Deleted entry ".$deletedentry->dn() );
		use Data::Dumper;
		$logger->debug("Entry: ".Dumper($deletedentry));
	    }
            my $result;
	    if ( ! $istest ) {
		$entry->delete();
		$result = $entry->update($ldap);
		if ( $result->code ) {
		    print "Error while deleting entry: ".
			$result->code.' ('.$result->error.")\n";
		    $logger->error("Error while deleting entry: ".
				   $result->code.' ('.$result->error.')');
		}
		else {
		    $deletecount++;
		    if ( $deletedentry ) {
			print " now adding deleted entry".$deletedentry->dn()."\n";
			$result = $deletedentry->update($ldap);
			if ( $result->code ) {
			    print "Error while adding deleted entry: ".
				$result->code.' ('.$result->error.")\n";
			    $logger->error("Error while adding deleted entry: ".
					   $result->code.' ('.$result->error.')');
			    #### TODO we need a config param for 
			    #### the directory here
                            use Net::LDAP::LDIF;
			    my $ldif = Net::LDAP::LDIF->new( 
				$deletedentry->dn().".ldif", "w", 
				onerror => 'undef' );
			    $ldif->write_entry($deletedentry);
			    $ldif->done();


			}
		    }
		}
	    }
	}
	
    } ### end     if ( $isdelete ) {
    elsif ( $iscleaner ) {
	foreach my $entry ( @entries ) {
	    $logger->debug("isCleaner: Working on entry ".$entry->dn() ); 
	    my $ischange=0 ;
	    foreach my $attrib (@attrs ) {
		my $isvalchange = 0;
		my @vals = $entry->get_value( $attrib );
		my @orivals = @vals;
		my @newvals;
		my @deletevals;
		foreach my $val ( @vals) {
		    my $orival = $val;
		    $code = '$val =~ s/'.$cleanerstring.'//; ';
		    eval $code;
		    if ( $val ne $orival ) {
#			print "found cleanerstring ($val != $orival)\n";
			$isvalchange++;
			if ( $isleavecleaner ) {
			    push @newvals, $orival;
			    push @deletevals, $val;
			}
			else {
			    push @newvals, $val if ($val || $val eq '0');
			    push @deletevals, $orival;
			}
		    }
		    else {
			push @newvals, $orival;
		    } 
		}
		if ( $isvalchange ) {
#		    print "is change: [". join ('|', @orivals) ."] [".
#			join ('|', @newvals)."] [". join ('|', @deletevals)."]\n";  
		    if ( @deletevals ) {
			@newvals = $data->findNewValues(\@newvals,\@deletevals);
		    }
		    if ( $data->areTheyDifferent(\@newvals,\@orivals) ) {
			$logger->info("#### In entry: ".$entry->dn() );
			$logger->info("In Attribute: $attrib");
			$logger->info ( $wouldbe."cleaning values ["
					.join ('|', @orivals)."] to ["
					.join ('|', @newvals)."]");  
			if ( ! $istest) {
			    $entry->changetype('modify');
			    
			    $entry->replace (
					     $attrib => \@newvals
					     );
			}
			$ischange=1;
		    }
		}
		else {
		    $logger->info( "no change");
		}
	    }
	    if ( $ischange && ! $istest) {	    
		my $updatemesg = $entry->update ( $ldap );
		$logger->info("Update result: ".$updatemesg->error() );
	    }
	}
    } ### end     elsif ( $iscleaner ) {
    elsif ( $isnewentry ) {
        for (my $i = 0 ; $i < $max ; $i++ ) {
	    my $basisentry = $entries[$i];
	    my $newentry = &createnewentry ($basisentry, $createnewentry);
	    $logger->info($wouldbe."Creating entry ". $newentry->dn());

	    my $result;
	    if ( ! $istest ) {
		$result = $newentry->update($ldap);
		if ( $result->code ) {
		    if ($result->code == 68) { # already exists
			$logger->warn("Entry exists already: (".$result->error.')');
		    } else {			
			print "Error while adding new entry: ".
			    $result->code.' ('.$result->error.")\n";
			$logger->error("Error while adding new entry: ".
				       $result->code.' ('.$result->error.')');
		    }
		}
	    }
	}
    }### end     elsif ( $isnewentry ) 
    elsif ( $isadder ) {
        my $isnew;
	foreach my $entry ( @entries ) {
	    $logger->debug("isAdder: Working on entry ".$entry->dn() ); 

	    # check if we need to move the RDN as well
	    my $moveRDN = 0;
	    my $oldRDN = $libldap->getrdn( $entry->dn() );
	    my $newRDNval = '';
	    my ($oldRDNattr,$oldRDNval) = split ("=",$oldRDN);
	    my $rdnvalIndex = 0;

	    $addstring =~ s/\\;/__SEMICOLON__/g;
	    my @defs = split(/;/, $addstring);
	    foreach my $def ( @defs ) {
		$def =~ s/__SEMICOLON__/;/g;
		my $isreplace=0;
		if ( $def =~/==/ ) {
		   $isreplace=1;
		   $def =~s/==/=/;
		} elsif ( $def =~ /=-/) {
		    $isdelete = 1;
		    $def =~s/=-/=/;
		}
		my ($at, $va) = split(/=/,$def,2);
		my $attr_is_casesensitive = 0;

		if ($oldRDNattr =~ /^$at$/i) {
		    $moveRDN = 1;
		}

	        if (grep {lc ($_) eq lc ($at)} @casesensitiveattrs) {
		    $attr_is_casesensitive = 1;
		}
		if ( $va =~/(.+)\((.*)\)$/ ) {
		    my $func = $1;
		    my @params = ();
		    if ($2) {
			@params = split /,/, $2;
		    }
		    foreach my $param ( @params ) {
			if ( $param =~/\#(.+)/ ) {
			    my $att = $1;
                            $logger->debug("main(): will fetch attr $att (param $param)");
			    if ($att =~ /^(entry)?dn$/i) {
				$param = $entry->dn();
			    } else {
				my @paramvalues = $entry->get_value($att);
				if (scalar @paramvalues == 1) {
				    $param = $paramvalues[0];
				} elsif (scalar @paramvalues == 0) {
				    $param = '';
				} else {
				    if ($moveRDN && $oldRDNattr eq $att) {
					### this assuemes new RDN gets build like this: uid==fn(#uid)
					### i.e. the RDN attr is the same and the only one as argument
					$rdnvalIndex = grep {$paramvalues[$_] eq $oldRDNval } 0..$#paramvalues;
				    }
				    $param = \@paramvalues;
				}
			    }
                            my $valstr = $param ? $param : ' ';
			    $logger->debug("main(): got: value: $valstr");
			} elsif ( $param =~ /%(\S+)%/) { ### for constants
			    $param = $1;
			}
		    }
		    push @params, $entry;
		    $logger->debug("main(): calling $func"); #, params ". join '+', @params);
		    $va = $conv->$func(@params); # could return string OR Array Ref
		    if ( $deleteonempty && ($va eq '' || (ref ($va) eq "ARRAY" && scalar(@{$va}) == 0 ))) {
			$isdelete = 1;
		    }
		} elsif ( $va =~ /\#(.+)/) { ### read attribute from other attribute's value(s)
		    my $otherattr = $1;
		    my @othervalues = $entry->get_value( $otherattr );
		    if (scalar @othervalues == 1) {
			$va = $othervalues[0];
		    } elsif (scalar @othervalues == 0) {
			$va = '';
		    } else {
			$va = \@othervalues;
		    }
		}

		$logger->debug( "working on def: $def attribute: $at");
		my @vals = $entry->get_value( $at );
		my $attr_exists = scalar @vals;
		my $isnewval = 1;
		if (!$forcereplace) {
		    foreach my $val ( @vals) {
			if ( ( !$attr_is_casesensitive && lc($val) eq lc($va) ) ||
			     ( $attr_is_casesensitive && $val eq $va ) )  {
			    $isnewval = 0;
			    last;
			}
		    }
		}
		if ( $isnewval || $isdelete) {
		    if ( ! $isnew ) {
			$entry->changetype('modify');	
		    }
		    $isnew++;
		    my $doing = $isreplace ? 'replacing' : 'adding';
		    $doing = $isdelete ? 'deleting' : $doing;
		    if ( defined $va && $va ne '' && (!(ref ($va) eq "ARRAY" && scalar(@{$va}) == 0 ))) { # could be "0"!!!
			if (ref ($va) eq "ARRAY" && scalar(@{$va}) > 1) {
			    $logger->info( $wouldbe."$doing $at: " . join ("|", @{$va}) . " entry "
					   .$entry->dn() );
			} else {
			    $logger->info( $wouldbe."$doing $at:  $va in entry "
					   .$entry->dn() );
			}
			if ( $isreplace && $moveRDN ) {
			    if (ref $va eq 'ARRAY') {
				$newRDNval = $va->[$rdnvalIndex];
			    } else {
				$newRDNval = $va;	
			    }
			    if ( ( !$attr_is_casesensitive && !grep { lc ($va) eq lc ($_) } @vals ) ||
				 ( $attr_is_casesensitive && !grep { $va eq $_ } @vals ) ) {
				$logger->info("### Replacement of this value leads to new RDN $at=$newRDNval");
				$va = [$va] unless ref $va eq 'ARRAY';
				$va = [@{$va},$oldRDNval]; # leave old value as DN change is a separate operation
			    }
			}
		    }
		    else {
			$logger->info( $wouldbe."deleting $at in entry "
				   .$entry->dn() ) if $isdelete && $attr_exists;
		    }
		    if ( ! $istest ) {
			if ( defined $va && $va ne '' && (!(ref ($va) eq "ARRAY" && scalar(@{$va}) == 0 )))  { ## could be "0" !!!
			    if ( $isreplace ) {
				$logger->info("Replacing");
				$entry->replace ( $at => $va );
			    }
			    elsif (!$isdelete) {
				$logger->info("Adding");
				$entry->add ( $at =>   $va   );
			    } 
			    else {
				$logger->info("Deleting");
				$entry->delete ( $at => $va );
			    }
			}
			elsif ( $isdelete && $attr_exists) {
			    $entry->delete( $at);
			}
		    }
		} 
		else {
		    $logger->info("value $va already exists in attribute $at");
		}
	    } # foreach my $def

	    if ( $isnew && ! $istest) {	    
		my $updatemesg = $entry->update ( $ldap );
		$logger->info( "Update result: ".$updatemesg->error() );

		if ($moveRDN && ($newRDNval || $newRDNval eq '0')) {
		    my $updatemesg = $libldap->change_rdn ( $ldap, $entry->dn(), 
							    "$oldRDNattr=$newRDNval",
							    1); # isdelete old rdn
		    $logger->info( "Change RDN ($oldRDNattr=$newRDNval) result: ".$updatemesg->error() );

		    ###XXXX delete oldrdn
		}
	    }
	}
    }### end     elsif ( $isadder ) {
    else {
	$logger->info("code: $code") if $code;
	
	foreach my $entry ( @entries ) {
	    $logger->debug("Normal run: Working on entry ".$entry->dn() ); 
	    my $ischange = 0;

	    # check if we need to move the RDN as well
	    my $moveRDN = 0;
	    my $oldRDN = $libldap->getrdn( $entry->dn() );
	    my $newRDNval = '';
	    my ($oldRDNattr,$oldRDNval) = split ("=",$oldRDN);

	    foreach my $attrib (@attrs ) {
		if ($oldRDNattr =~ /^$attrib$/i) {
		    $moveRDN = 1;
		}

		my $isvalchange = 0;

		my @vals = $entry->get_value( $attrib );
		my @newvals;
		foreach my $val ( @vals) {
		    my $orival = $val;
		    if ( $isregexp) {
			eval $code;
		    }
		    else {
			$val =~ s/$findstring/$replacestring/g;
		    }
		    
		    if ( $orival ne $val ) {
			$ischange++;
			$isvalchange++;
			$logger->info("#### In entry: ".$entry->dn() );
			$logger->info("In Attribute: $attrib");
			$logger->info("###".$wouldbe."Replacing:\n$orival\n#### with:\n$val");
		    }
		    if ($moveRDN && $orival =~ /^$oldRDNval$/i && lc($orival) ne lc($val) ) {
			$logger->info("### Replacement of this value leads to new RDN $attrib=$val");
			$newRDNval = $val;
			$isvalchange--; # so it is 0 again if the attr had only one, the RDN, value
			                # if there were more values, it is the number of those
			push @newvals, $orival; # leave old value as DN change is a separate operation
		    } else {
			push @newvals, $val;
		    }
		}
	    
	    
		if ( $isvalchange && ! $istest) {
		    $entry->changetype('modify');
		
		    $entry->replace (
				     $attrib => \@newvals
				     );
		} 
	    }
	    if ( $ischange && ! $istest) {

		my $updatemesg = $entry->update ( $ldap );
		$logger->info( "Update result: ".$updatemesg->error() );

		if ($moveRDN && ($newRDNval || $newRDNval eq '0')) {
		    my $updatemesg = $libldap->change_rdn ( $ldap, $entry->dn(), 
							    "$oldRDNattr=$newRDNval",
							    1); # isdelete old rdn
		    $logger->info( "Change RDN result: ".$updatemesg->error() );
		}
	    }
	}
    }
    
    if ($iscsvoutput) {
	close CSV unless $istest;
    }
}





#if ( $config{features}) {
#    addfeatures(\%config);
#}

if ($config{debugmode}) {  
    logconfig(\%config);
}



END:
unlink $pidfile; 

ENDWITHOUT:
#print ( "############  ldapcleaner ended ############\n");
$logger->info ( "############  ldapcleaner ended ############" );


exit();


sub extractFormatstring {
    my ($formatstring, $mode) = @_;

    $logger->debug("extractFormatstring: string: [$formatstring], mode: [$mode]");

    my ($header, $format, $sep, $quote ) = 
	split /_/, $formatstring;

    $logger->debug("Format: [$format]");

    if ( $sep ) {
	$sep =~ s/([*+{}.\|\]\[\-\\])/\\$1/g; 
    }
#    if ( $sep eq '|' ) { $sep = '\|'; }

    if ( ! $quote ) { $quote = '"'; }

    if ( ! defined($header) ) { $header = 0; }

    if ( $mode eq "out") {
	if ( ! defined($sep) ) { $sep = 0;}
    } elsif ( $mode eq "in" ) {
	if ( ! defined($sep) ) { $sep = ',';}
    }


    $logger->debug("${mode}putformat: Head: [$header], form: [$format], sep: [$sep], quote: [$quote]"); 

    return ( $header, $format, $sep, $quote );

}




sub logconfig {
    my ($rh_config) = @_;


    foreach my $key ( keys %{$rh_config->{options}} ) {
	my $val = $rh_config->{$key} ? $rh_config->{$key} : " ";
	$logger->debug("$key is set to $val");
    }

#    $logger->debug("debugmode is set: $rh_config->{debugmode}");
#    $logger->debug("configfile: $rh_config->{configfile}");
#    $logger->debug("inputdir: $rh_config->{inputdir}");
#    $logger->debug("archivedir: $rh_config->{archivedir}");
#    $logger->debug("archivetimetolive: $rh_config->{archivetimetolive}");
#    $logger->debug("loglevel: $rh_config->{loglevel}");
#    $logger->debug("logfile: $rh_config->{logfile}");

    $logger->debug("known ldapservers:");
    foreach my $server ( keys %{$rh_config->{ldapserver}} ) {
	$logger->debug("    $server: ");
	$logger->debug("       manager: $rh_config->{ldapserver}{$server}{manager}");
	$logger->debug("       tls: $rh_config->{ldapserver}{$server}{tls}");
    }

    foreach my $feature ( keys %{$rh_config->{emailinfo}} ) {
	$logger->debug(" mailfeature $feature: $rh_config->{emailinfo}{$feature} ");
    }


    $logger->debug("mappings defined:");
    foreach my $attr ( keys %{$rh_config->{mappings}} ) {
	$logger->debug("    Mapping in attribute $attr:");
	foreach my $key ( keys %{$rh_config->{mappings}{$attr}} ) {
	    $logger->debug("      $key => $rh_config->{mappings}{$attr}{$key}");    
	}
    }

}


sub addfeatures {
    my ($rh_config) = @_;

    foreach my $feature (split /_/, $rh_config->{features} ) {
	$rh_config->{$feature} = 1;
	$logger->debug("Feature $feature is set");
    }
}

sub resetcounter {
    my ($rh_amounts) = @_;

    $rh_amounts->{all} = 0;
    $rh_amounts->{ok} = 0;
    $rh_amounts->{err} = 0;
    $rh_amounts->{file} = 0;
    $rh_amounts->{fileok} = 0;
    $rh_amounts->{fileerr} = 0;
    $rh_amounts->{filenotready} = 0;
}

sub addcounters {
    my ($rh_totalamounts, $rh_amounts) = @_;

    $rh_totalamounts->{all} += $rh_amounts->{all};
    $rh_totalamounts->{ok}  += $rh_amounts->{ok};
    $rh_totalamounts->{err} += $rh_amounts->{err};
}


sub gettimestamp {

    	my ( $sek, $min, $hour, $day, $mon, $year ) = localtime();
	my $timestamp = sprintf("am %02d.%02d.%04d um %02d:%02d:%02d Uhr", 
				$day, $mon+1, $year+1900, 
				$hour, $min, $sek);
	return ($timestamp);
}


sub myquotemeta {
    my ($string ) = @_;

    $string =~ s/\\\$/\$/g;
#    $string = quotemeta($string);

    return $string;
}

sub loadattributesfromfile {
     my ($filename ) = @_;

     open FH, "<$filename";

     my $val = '';
     foreach (<FH>) {
	 chomp;
	 $val .="$_;"
     }

     $val =~ s/;$//;

     return $val;
}

sub createnewentry {
    my ($basisentry, $createnewentry) = @_;
    my ($classesstr, $rdnattr, $newattributesstr) = split / ?; ?/, $createnewentry;

    my $entry = Net::LDAP::Entry->new;
    my @classes = split /,/, $classesstr;
    $entry->add( "objectClass" => \@classes );

    foreach my $def ( split /,/, $newattributesstr ) {
	my ( $name, $value ) = split /=/, $def, 2;
	if ($name =~ /:$/) {
	    chop $name;
	    $value = decode_base64($value);
	}
	$logger->debug("Attribute $name: $value");
	$entry->add( $name => $value );
    }
    my $rdnval = $entry->get_value($rdnattr);
    my $dn = $rdnattr.'='.$rdnval.','.$basisentry->dn();
    $logger->debug("New Entry's DN: $dn");
    $entry->dn($dn);

    return $entry;
}

sub createdeletedentry {

    my ($oldentry, $definitions) = @_;

    $definitions =~ s/^"//;
    $definitions =~ s/"$//;

    my @definitions = split /;/, $definitions;
    if ( $#definitions != 4 ) {
	$logger->error("wrong number of deleted entry definitions: $#definitions");
	print "wrong number of deleted entry definitions: $#definitions\n";
	return undef;
    }

    my ( $classesstr, $attributesstr, $newattributesstr, 
	 $rdnattr, $basedn) = @definitions; 

    my $entry = Net::LDAP::Entry->new;

    my @classes = split /,/, $classesstr;

    $entry->add( "objectClass" => \@classes );

    foreach my $attr ( split /,/, $attributesstr ) {
	my @vals = $oldentry->get_value($attr);
	if ( $vals[0] ) {
	    $entry->add( $attr => \@vals );
	}
    }

    foreach my $def ( split /,/, $newattributesstr ) {
	my ( $newattr, $oldattr ) = split /=/, $def;
	if ( $oldattr =~ /['"](.+)["']/ ) {
	    $entry->add( $newattr => $1 );
	}
	else {
	    my @vals = $oldentry->get_value($oldattr);
	    if ( $vals[0] ) {
		$entry->add( $newattr => \@vals );
	    }
	}
    }

    my $rdnval = $entry->get_value($rdnattr);
    my $dn = $rdnattr.'='.$rdnval.','.$basedn;
    $entry->dn($dn);

    $entry->changetype("add");

    return $entry;

}
