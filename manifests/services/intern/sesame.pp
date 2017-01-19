# == Class: dhrep::services::intern::sesame
#
# Class to install and configure sesame.
# Creates initial repos textgrid-nonpublic and textgrid-public and adds initial
# triples.
#
class dhrep::services::intern::sesame (
  $scope = undef,
) inherits dhrep::params {

  include dhrep::services::tomcat_sesame

  $version       = '2.7.13'
  $file          = "openrdf-sesame-${version}-sdk.tar.gz"

  $_catname      = $::dhrep::services::tomcat_sesame::catname
  $_http_port    = $::dhrep::services::tomcat_sesame::http_port
  $_user         = $::dhrep::services::tomcat_sesame::user
  $_group        = $::dhrep::services::tomcat_sesame::group
  $_backupdir    = $::dhrep::params::backupdir
  $_optdir       = $::dhrep::params::optdir

  ###
  # do install sesame: download and extract
  ###
  dhrep::tools::tgstaging { $file:
    source  => "http://sourceforge.net/projects/sesame/files/Sesame%202/${version}/${file}/download",
    target  => "/home/${_user}",
    creates => "/home/${_user}/openrdf-sesame-${version}",
    require => Dhrep::Resources::Servicetomcat[$_catname],
  }
  ~>
  tomcat::war { 'openrdf-workbench.war':
    war_ensure    => present,
    catalina_base => "/home/${_user}/${_catname}",
    war_source    => "/home/${_user}/openrdf-sesame-${version}/war/openrdf-workbench.war",
    require       => Dhrep::Resources::Servicetomcat[$_catname],
  }
  ~>
  tomcat::war { 'openrdf-sesame.war':
    war_ensure    => present,
    catalina_base => "/home/${_user}/${_catname}",
    war_source    => "/home/${_user}/openrdf-sesame-${version}/war/openrdf-sesame.war",
    require       => [Dhrep::Resources::Servicetomcat[$_catname],Tomcat::War['openrdf-workbench.war']],
  }

  file { "/home/${_catname}/mime.ttl":
    ensure  => present,
    owner   => $_user,
    mode    => '0644',
    source  => 'puppet:///modules/dhrep/rdf/mime.ttl',
    require => User[$_catname]
  }

  # FIXME Ubbo!
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

  # FIXME Ubbo!
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
    owner   => $_user,
    group   => $_group,
    mode    => '0755',
    require => File[$_backupdir],
  }
  file{ "${_optdir}/sesame-backup.sh" :
    source  => "puppet:///modules/dhrep/opt/dhrep/${scope}/sesame-backup.sh",
    owner   => $_user,
    group   => $_group,
    mode    => '0700',
    require => [File[$_optdir],File["${_backupdir}/sesame"]],
  }
  cron { 'sesame-backup' :
    command  => "${_optdir}/sesame-backup.sh",
    user     => $_user,
    hour     => 22,
    minute   => 33,
  }

  ###
  # nrpe
  ###
  nrpe::plugin { 'check_http_sesame':
    plugin => 'check_http',
    args   => "-H localhost -p ${_http_port} -u /openrdf-sesame/repositories -k \"Accept: application/xml\" -s /openrdf-sesame/repositories/textgrid-nonpublic -s /openrdf-sesame/repositories/textgrid-public",
  }
  file { "${_optdir}/check_sesame_backups.sh" :
    source  => "puppet:///modules/dhrep/opt/dhrep/${scope}/check_sesame_backups.sh",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File["${_optdir}/sesame-backup.sh"],
  }s
  nrpe::plugin { 'check_sesame_backups':
    plugin     => 'check_sesame_backups.sh',
    libexecdir => $_optdir,
  }
}
