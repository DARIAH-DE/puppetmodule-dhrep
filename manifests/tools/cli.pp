# == Class: dhrep::tools::cli
#
# Class for cli-tools, yeah!
#
class dhrep::tools::cli (
  $scope = undef,
) inherits dhrep::params {

  if $scope == 'textgrid' {
    $_optdir = $::dhrep::params::optdir

    package {
      'xqilla': ensure => present;
      'jq':     ensure => present;
    }

    ###
    # shell tools for repo inspection
    ###
    file { "${_optdir}/functions.d":
      ensure  => directory,
      owner   => root,
      group   => root,
      mode    => '0755',
      require => File[$_optdir],
    }
    file { "${_optdir}/functions.d/textgrid-shared.sh":
      mode    => '0777',
      source  => 'puppet:///modules/dhrep/opt/dhrep/textgrid/functions.d/textgrid-shared.sh',
      require => File["${_optdir}/functions.d"],
    }
    file { "${_optdir}/functions.d/inspect.sh":
      mode    => '0777',
      source  => 'puppet:///modules/dhrep/opt/dhrep/textgrid/functions.d/inspect.sh',
      require => File["${_optdir}/functions.d"],
    }
    file { "${_optdir}/inspect-tgobject.sh":
      mode    => '0777',
      source  => 'puppet:///modules/dhrep/opt/dhrep/textgrid/inspect-tgobject.sh',
      require => File[$_optdir],
    }

    ###
    # consistency check
    ###
    file { "${_optdir}/consistency":
      ensure  => directory,
      owner   => root,
      group   => root,
      mode    => '0755',
      require => File[$_optdir],
    }
    file { "${_optdir}/consistency/check_es_index.sh":
      mode    => '0777',
      source  => 'puppet:///modules/dhrep/opt/dhrep/textgrid/consistency/check_es_index.sh',
      require => [File["${_optdir}/consistency"],File['/etc/elasticsearch/masternode/scripts/idMatchesTextgridUri.groovy']],
    }
    # the nagios command for es-index check
    nrpe::plugin { 'check_es_index_consistency':
      plugin     => 'check_es_index.sh',
      args       => 'nagios',
      libexecdir => "${_optdir}/consistency",
    }

    ###
    # the ldap pw for inspect-tgobject.sh / textgrid-shared.sh
    ###
    file { '/etc/dhrep/consistency_check.conf' :
      content => inline_template('LDAP_PW=\'<%=scope.lookupvar("profiles::textgridrepository::tgauth_binddn_pass")%>\''),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }

    ###
    # README for the tools.
    ###
    file { "${_optdir}/README.md":
      mode    => '0644',
      source  => 'puppet:///modules/dhrep/opt/dhrep/textgrid/README.md',
      require => File[$_optdir],
    }

  }
}
