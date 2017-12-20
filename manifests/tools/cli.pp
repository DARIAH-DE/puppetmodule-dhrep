# == Class: dhrep::tools::cli
#
# Class for cli-tools, yeah!
#
class dhrep::tools::cli (
  $scope = undef,
) inherits dhrep::params {

  if $scope == 'textgrid' {
    $_optdir = $::dhrep::params::optdir

    package { 'xqilla': ensure => present }

    ###
    # shell tools for repo inspection
    ###
    file { '/opt/dhrep/functions.d':
      ensure  => directory,
      owner   => root,
      group   => root,
      mode    => '0755',
      require => File[$_optdir],
    }
    file { '/opt/dhrep/functions.d/textgrid-shared.sh':
      mode   => '0777',
      source => 'puppet:///modules/dhrep/opt/dhrep/textgrid/functions.d/textgrid-shared.sh',
      require => File['/opt/dhrep/functions.d'],
    }
    file { '/opt/dhrep/functions.d/inspect.sh':
      mode   => '0777',
      source => 'puppet:///modules/dhrep/opt/dhrep/textgrid/functions.d/inspect.sh',
      require => File['/opt/dhrep/functions.d'],
    }
    file { '/opt/dhrep/inspect-tgobject.sh':
      mode   => '0777',
      source => 'puppet:///modules/dhrep/opt/dhrep/textgrid/inspect-tgobject.sh',
      require => File[$_optdir],
    }

    ###
    # the ldap pw for inspect-tgobject.sh / textgrid-shared.sh
    ###
    file { "/etc/dhrep/consistency_check.conf" :
      content => inline_template('LDAP_PW=\'<%=scope.lookupvar("profiles::textgridrepository::tgauth_binddn_pass")%>\''),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  }
}
