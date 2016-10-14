# == Class: dhrep::services::intern::sesame
#
# Class to install and configure sesame.
# Creates initial repos textgrid-nonpublic and textgrid-public and adds initial
# triples.
#
class dhrep::services::intern::sesame (
  $scope = undef,
) inherits dhrep::params {

  $catname       = 'tomcat-sesame'
  $version       = '2.7.13'
  $file          = "openrdf-sesame-${sesame_version}-sdk.tar.gz"

  $_catname      = $::dhrep::params::config['tomcat_sesame']['catname']
  $_http_port    = $::dhrep::params::config['tomcat_sesame']['http_port']
  $_control_port = $::dhrep::params::config['tomcat_sesame']['control_port']
  $_jmx_port     = $::dhrep::params::config['tomcat_sesame']['jmx_port']
  $_gid          = $::dhrep::params::config['tomcat_sesame']['gid']
  $_uid          = $::dhrep::params::config['tomcat_sesame']['uid']
  $_backupdir    = $::dhrep::params::backupdir
  $_optdir       = $::dhrep::params::optdir

  ###
  # create tomcat
  ###
  dhrep::resources::servicetomcat { $_catname:
    gid          => $_gid,
    uid          => $_uid,
    http_port    => $_http_port,
    control_port => $_control_port,
    jmx_port     => $_jmx_port,
  }

  dhrep::tools::tgstaging { $file:
    source  => "http://sourceforge.net/projects/sesame/files/Sesame%202/${version}/${file}/download",
    target  => "/home/${_catname}",
    creates => "/home/${_catname}/openrdf-sesame-${version}",
  }
  ~>
  tomcat::war { 'openrdf-workbench.war':
    war_ensure    => present,
    catalina_base => "/home/${_catname}/${_catname}",
    war_source    => "/home/${_catname}/openrdf-sesame-${version}/war/openrdf-workbench.war",
    require       => [Dhrep::Resources::Servicetomcat[$_catname]],
  }
  ~>
  tomcat::war { 'openrdf-sesame.war':
    war_ensure    => present,
    catalina_base => "/home/${_catname}/${_catname}",
    war_source    => "/home/${_catname}/openrdf-sesame-${version}/war/openrdf-sesame.war",
    require       => [Dhrep::Resources::Servicetomcat[$_catname],Tomcat::War['openrdf-workbench.war']],
  }

  file { "/home/${_catname}/mime.ttl":
    ensure  => present,
    owner   => $_catname,
    mode    => '0644',
    source  => 'puppet:///modules/dhrep/rdf/mime.ttl',
    require => User[$_catname]
  }

  unless $sesame_nonpublic_repo_created {
    dhrep::resources::create_rdf_repository{"${scope}-nonpublic":
      port => $_http_port,
      user => $_catname,
    }
    ->
    file {'/etc/facter/facts.d/sesame_nonpublic.txt':
      content => 'sesame_nonpublic_repo_created=true',
    }
  }

  unless $sesame_public_repo_created {
    dhrep::resources::create_rdf_repository{"${scope}-public":
      port => $_http_port,
      user => $_catname,
    }
    ->
    file {'/etc/facter/facts.d/sesame_public.txt':
      content => 'sesame_public_repo_created=true',
    }
  }

  ###
  # sesame backup script
  ###
  file { "${_backupdir}/sesame" :
    ensure  => directory,
    owner   => $_catname,
    group   => $_catname,
    mode    => '0755',
    require => File[$_backupdir],
  }
  file{ "${_optdir}/sesame-backup.sh" :
    source  => 'puppet:///modules/dhrep/opt/dhrep/sesame-backup.sh',
    owner   => $_catname,
    group   => $_catname,
    mode    => '0700',
    require => [File[$_optdir],File["${_backupdir}/sesame"]],
  }
  cron { 'sesame-backup' :
    command  => "${_optdir}/sesame-backup.sh",
    user     => $catname,
    hour     => 22,
    minute   => 33,
  }

  ###
  # nrpe
  ###
  dariahcommon::nagios_service { 'check_http_sesame':
    command => "/usr/lib/nagios/plugins/check_http -H localhost -p 9091 -u /openrdf-sesame/repositories -k \"Accept: application/xml\" -s /openrdf-sesame/repositories/textgrid-nonpublic -s /openrdf-sesame/repositories/textgrid-public",
  }
  file { "${_optdir}/check_sesame_backups.sh" :
    source  => 'puppet:///modules/dhrep/opt/dhrep/check_sesame_backups.sh',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["${_optdir}/sesame-backup.sh"],
  }
  dariahcommon::nagios_service { 'check_sesame_backups':
    command => "${_optdir}/check_sesame_backups.sh",
    require => File["${_optdir}/check_sesame_backups.sh"],
  }

}
