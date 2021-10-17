# == Class: dhrep::services::intern::sesame
#
# === Description
#
# Class to install and configure sesame.
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

    # ports temporay for migration, change to $_http_port later / put to params
    if $::dhrep::services::tomcat_sesame::use_tomcat {
      $rdf4j_http_port    = 9089
      $rdf4j_jmx_port     = 9911
    } else {
      $rdf4j_http_port    = $::dhrep::services::tomcat_sesame::http_port
      $rdf4j_jmx_port     = $::dhrep::services::tomcat_sesame::jmx_port

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
    }

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
