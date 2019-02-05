package DAASIlib::Convert;
use strict;
use warnings;

use Log::Log4perl qw(:levels);
use Log::Log4perl::Level;
use feature qw(state);
my $logger = Log::Log4perl->get_logger('');
use DAASIlib::LDAP;
our $libldap = new DAASIlib::LDAP;
our ($ldap,$rh_ldapserver);


sub makeEPPN {
    my $self = shift;
    my ($uid) = @_;

    return $uid . '@dariah.eu';
}

sub makeRbacId {
    my $self = shift;
    my ($dariahMappedIds,$uid,$eduPersonPrincipalName,$dariahTextGridRbacId) = @_;
    if ( $dariahTextGridRbacId ) {
	return $dariahTextGridRbacId;
    } elsif ( $dariahMappedIds ) {
	return $dariahMappedIds;
    } elsif ( $uid =~ /\@/ ) {
	return $uid;
    } elsif ( $eduPersonPrincipalName ) {
	return $eduPersonPrincipalName;
    } else {
	return 'gnuelpfix@gnuelpfix.gnuelpfix';
    }
}



our %whitelist; # static
### gives true if entry is freemailer or unknown, i.e. not in whitelist
sub isBlackOrGrey {
    my $self = shift;
    my ($entry) = @_;
    
    my $result = 1;

    if ($entry) {
        my @mail = $entry->get_value('mail');
        my $mail = $mail[0];

        if (! scalar %whitelist) {
            my $filter = "(&(objectClass=dNSDomain)(dc=whitelist))";
            $rh_ldapserver->{filter} = $filter;
            my $oldbasedn = $rh_ldapserver->{basedn};
            $rh_ldapserver->{basedn} = 'dc=dariah,dc=eu';
            my $ldap = $libldap->connectServer($rh_ldapserver);

            if ( ! $ldap ) {
                $logger->error( "isBlackOrGrey:() couldn't connect to LDAP server");
            } else {
                my $mesg = $libldap->doSearch($ldap, $rh_ldapserver);
                my $entry = $mesg->pop_entry();
                if ($entry) {
                    my @unis = $entry->get_value('cNAMERecord');
                    %whitelist = map { lc $_ => 1 } @unis;
                    $logger->info( "isBlackOrGrey:() loaded whitelist");
                }
            }
            $rh_ldapserver->{basedn} = $oldbasedn;

        }

        if ($mail =~ /\@(.+)$/) {
            my $suffix = lc $1;
            if (exists $whitelist{$suffix}) {
                $logger->debug( "isBlackOrGrey:() $mail is in whitelist");
                $result = 0; ### must not send to whitelist addresses
            } else {
                $logger->debug( "isBlackOrGrey:() $mail not in whitelist");
            }
        }
    }
    return $result;
}

### gives true if entry is in whitelist
sub isWhite {
    my $self = shift;
    my ($entry) = @_;

    my $result = $self->isBlackOrGrey($entry);

    return !$result;
}

1;
