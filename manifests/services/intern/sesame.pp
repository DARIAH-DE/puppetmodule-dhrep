# == Class: dhrep::services::intern::sesame
#
# === Description
#
# Class to install and configure rdf4j.
# It is still named sesame for backwards compatibility reasons.
# Shall we better name it "triplestore" so we are safe for a jena switch? ;-)
#
# === Notes
#
# Initial database creation is now done by the script /opt/dhrep/init_databases.sh! Creates initial repos textgrid-nonpublic and textgrid-public and adds initial triples.
#
# === Parameters
#
# [*scope*]
#   textgrid or dariah (textgrid only at the moment, there is no sesame installation for the DARIAH-DE Repository eright now.
#
class dhrep::services::intern::sesame (
  $scope = undef,
  $docker_image_registry = 'docker.gitlab.gwdg.de',
  $docker_image_name     = 'dariah-de/textgridrep/rdf4j-service/main',
  $docker_image_tag      = 'latest',
) inherits dhrep::params {

  include dhrep::services::tomcat_sesame

  $_http_port    = $::dhrep::services::tomcat_sesame::http_port
  $_backupdir    = $::dhrep::params::backupdir
  $_optdir       = $::dhrep::params::optdir

  #$uid = $::dhrep::params::config['rdf4j']['uid']
  #$gid = $::dhrep::params::config['rdf4j']['gid']
  $group = 'rdf4j'
  $user = 'rdf4j'
  $uid = 1020
  $gid = 1020

  $rdf4j_http_port    = $::dhrep::services::tomcat_sesame::http_port
  $rdf4j_jmx_port     = $::dhrep::services::tomcat_sesame::jmx_port

  if ! defined(Group[$group]) {
    group { $group:
      ensure =>  present,
      gid    =>  $gid,
    }
  }
  if ! defined(User[$user]) {
    user { $user:
      ensure => present,
      uid    => $uid,
      gid    => $gid,
    }
  }

  ###
  # checkout rdf4j init script and tools
  ###
  # FIXME use vcsrepo!
  # FIXME checkout default branch (develop?)
  exec { 'git_clone_rdf4j-service':
    path    => ['/usr/bin','/bin','/usr/sbin'],
    command => 'git clone https://gitlab.gwdg.de/dariah-de/textgridrep/rdf4j-service.git /usr/local/src/rdf4j-service',
    creates => '/usr/local/src/rdf4j-service',
    require => Package['git'],
  }

  ###
  # sesame backup script
  ###
  file { "${_backupdir}/sesame" :
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => File[$_backupdir],
  }
  file{ "${_optdir}/sesame-backup.sh" :
    source  => "puppet:///modules/dhrep/opt/dhrep/${scope}/sesame-backup.sh",
    owner   => $user,
    group   => $group,
    mode    => '0700',
    require => [File[$_optdir],File["${_backupdir}/sesame"]],
  }
  cron { 'sesame-backup' :
    command     => "${_optdir}/sesame-backup.sh",
    environment => 'PATH=/bin:/usr/bin:/usr/sbin',
    user        => $user,
    hour        => 22,
    minute      => 33,
  }
  cron { 'clean-old-sesame-backups' :
    command     => 'find  /var/dhrep/backups/sesame -type f -mtime +90 -delete',
    environment => 'PATH=/bin:/usr/bin:/usr/sbin',
    user        => $user,
    hour        => 22,
    minute      => 3,
  }

  file { '/opt/docker-triplestore/mime.ttl':
    ensure => file,
    mode   => '0644',
    source => 'puppet:///modules/dhrep/rdf/mime.ttl',
  }

  include dhrep::services::intern::docker
  file { '/opt/docker-triplestore':
    ensure  => directory,
  }

  file { '/opt/docker-triplestore/docker-compose.yml':
    ensure  => file,
    content => epp('dhrep/opt/docker-triplestore/docker-compose.yml.epp', {
        image     => "${docker_image_registry}/${docker_image_name}:${docker_image_tag}",
        http_port => $rdf4j_http_port,
        jmx_port  => $rdf4j_jmx_port,
    }),
  }

  docker::image { "${docker_image_registry}/${docker_image_name}":
    ensure    => latest,
    image_tag => $docker_image_tag,
  }
  -> docker_compose { 'triplestore':
    ensure        => present,
    compose_files => ['/opt/docker-triplestore/docker-compose.yml'],
    require       => [
      File['/opt/docker-triplestore/docker-compose.yml'],
    ],
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
  }
  nrpe::plugin { 'check_sesame_backups':
    plugin     => 'check_sesame_backups.sh',
    libexecdir => $_optdir,
  }
}
