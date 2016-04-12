# == Class: dhrep::services::intern::sesame
#
# Class to install and configure sesame.
# Creates initial repos textgrid-nonpublic 
# and textgrid-public and adds initial triples.
#
class dhrep::services::intern::sesame (
  $scope          = undef
){

  $tgname         = 'tomcat-sesame'
  $http_port      = '9091'
  $control_port   = '9006'
  $jmx_port       = '9991'
  $sesame_version = '2.7.13'
  $sesame_file    = "openrdf-sesame-${sesame_version}-sdk.tar.gz"

  #require textgrid::resources::create_rdf_repository

  dhrep::resources::servicetomcat { $tgname:
    gid          => '1008',
    uid          => '1008',
    http_port    => $http_port,
    control_port => $control_port,
    jmx_port     => $jmx_port,
  }

  dhrep::tools::tgstaging { $sesame_file:
    source  => "http://sourceforge.net/projects/sesame/files/Sesame%202/${sesame_version}/${sesame_file}/download",
    target  => "/home/${tgname}",
    creates => "/home/${tgname}/openrdf-sesame-${sesame_version}",
  }

#  $tgcache = '/var/cache/textgrid/'
#  file { $tgcache:
#    ensure => directory,
#  }

#  staging::file { $sesame_file:
#    source  => "http://sourceforge.net/projects/sesame/files/Sesame%202/${sesame_version}/${sesame_file}/download",
#    target  => "${tgcache}/${sesame_file}",
#  }
#  ->
#  staging::extract { $sesame_file:
#    source  => "${tgcache}/${sesame_file}",
#    target  => "/home/${tgname}",
#    creates => "/home/${tgname}/openrdf-sesame-${sesame_version}",
#  }
  ~>
  tomcat::war { 'openrdf-workbench.war':
    war_ensure    => present,
    catalina_base => "/home/${tgname}/${tgname}",
    war_source    => "/home/${tgname}/openrdf-sesame-${sesame_version}/war/openrdf-workbench.war",
    require       => [Dhrep::Resources::Servicetomcat[$tgname]],
  }
  ~>
  tomcat::war { 'openrdf-sesame.war':
    war_ensure    => present,
    catalina_base => "/home/${tgname}/${tgname}",
    war_source    => "/home/${tgname}/openrdf-sesame-${sesame_version}/war/openrdf-sesame.war",
    require       => [Dhrep::Resources::Servicetomcat[$tgname],Tomcat::War['openrdf-workbench.war']],
  }

  file { "/home/${tgname}/mime.ttl":
    ensure  => present,
    owner   => $user,
    mode    => '0644',
    source  => 'puppet:///modules/dhrep/rdf/mime.ttl',
    require => User[$tgname]
  }

  unless $sesame_nonpublic_repo_created {
    dhrep::resources::create_rdf_repository{'textgrid-nonpublic':
      port => '9091',
      user => $tgname,
    }
    ->
    file {'/etc/facter/facts.d/sesame_nonpublic.txt':
      content => 'sesame_nonpublic_repo_created=true',
    }
  }

  unless $sesame_public_repo_created {
    dhrep::resources::create_rdf_repository{'textgrid-public':
      port => '9091',
      user => $tgname,
    }
    ->
    file {'/etc/facter/facts.d/sesame_public.txt':
      content => 'sesame_public_repo_created=true',
    }
  }

  ###
  # sesame backup script
  ###
  file { '/var/textgrid/backups/sesame' :
    ensure  => directory,
    owner   => $tgname,
    group   => $tgname,
    mode    => '0755',
    require => File['/var/textgrid/backups'],
  }
  file{ '/opt/dhrep/sesame-backup.sh' :
    source  => 'puppet:///modules/dhrep/opt/dhrep/sesame-backup.sh',
    owner   => $tgname,
    group   => $tgname,
    mode    => '0700',
    require => [File['/opt/dhrep'],File['/var/textgrid/backups/sesame']],
  }
  cron { 'sesame-backup' :
    command  => '/opt/dhrep/check_sesame_backups.sh',
    user     => $tgname,
    hour     => 22,
    minute   => 33,
  }

  ###
  # nrpe
  ###
  dariahcommon::nagios_service { 'check_http_sesame':
    command => "/usr/lib/nagios/plugins/check_http -H localhost -p 9091 -u /openrdf-sesame/repositories -k \"Accept: application/xml\" -s /openrdf-sesame/repositories/textgrid-nonpublic -s /openrdf-sesame/repositories/textgrid-public",
  }
  file { '/opt/dhrep/check_sesame_backups.sh' :
    source  => 'puppet:///modules/dhrep/opt/dhrep/check_sesame_backups.sh',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/opt/dhrep/sesame-backup.sh'],
  }
  dariahcommon::nagios_service { 'check_sesame_backups':
    command => "/opt/dhrep/check_sesame_backups.sh",
    require => File['/opt/dhrep/check_sesame_backups.sh'],
  }

}
