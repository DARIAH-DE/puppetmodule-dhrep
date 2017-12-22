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
    file { "${_optdir}/functions.d":
      ensure  => directory,
      owner   => root,
      group   => root,
      mode    => '0755',
      require => File[$_optdir],
    }
    file { "${_optdir}/functions.d/textgrid-shared.sh":
      mode   => '0777',
      source => 'puppet:///modules/dhrep/opt/dhrep/textgrid/functions.d/textgrid-shared.sh',
      require => File["${_optdir}/functions.d"],
    }
    file { "${_optdir}/functions.d/inspect.sh":
      mode   => '0777',
      source => 'puppet:///modules/dhrep/opt/dhrep/textgrid/functions.d/inspect.sh',
      require => File["${_optdir}/functions.d"],
    }
    file { "${_optdir}/inspect-tgobject.sh":
      mode   => '0777',
      source => 'puppet:///modules/dhrep/opt/dhrep/textgrid/inspect-tgobject.sh',
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
      mode   => '0777',
      source => 'puppet:///modules/dhrep/opt/dhrep/textgrid/consistency/check_es_index.sh',
      require => [File["${_optdir}/consistency"],File['/etc/elasticsearch/masternode/scripts/idMatchesTextgridUri.groovy']],
    }
    # the es-index consistency check needs a groovy script to be present in elasticsearch
    file { '/etc/elasticsearch/masternode/scripts/idMatchesTextgridUri.groovy':
      ensure  => file,
      owner   => 'elasticsearch',
      group   => 'elasticsearch',
      mode    => '0640',
      source  => 'puppet:///modules/dhrep/etc/elasticsearch/masternode/scripts/idMatchesTextgridUri.groovy',
      require => File['/etc/elasticsearch/masternode/scripts/'],
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