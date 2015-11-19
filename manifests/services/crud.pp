# == Class: dhrep::services::crud
#
# Class to install and configure tgcrud/dhcrud
#
class dhrep::services::crud (
  $scope            = undef,
  $short            = 'tgcrud',
  $crud_name        = 'tgcrud-webapp',
  $crud_version     = 'latest',
  $use_messaging    = true,
  $publish_secret   = undef,
) inherits dhrep::params {

  include dhrep::services::intern::javagat
  include dhrep::services::tomcat_crud

  $catname = $dhrep::services::tomcat_crud::catname
  $user    = 'storage'
  $group   = 'storage'

  package { $crud_name:
    ensure  => $crud_version,
    require => [Exec['update_dariah_apt_repository'],Dhrep::Resources::Servicetomcat[$catname]],
  }

  ###
  # config
  ###

  file { "/etc/${scope}/${short}":
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { "/etc/${scope}/${short}/${short}.properties":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("dhrep/etc/${scope}/${short}/${short}.properties.erb"),
    require => File["/etc/${scope}/${short}"],
  }

  file { "/etc/${scope}/${short}/beans.properties":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("dhrep/etc/${scope}/${short}/beans.properties.erb"),
    require => File["/etc/${scope}/${short}"],
  }

  ###
  # logging
  ###

  file { "/etc/${scope}/${short}/${short}.log4j":
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => template("dhrep/etc/${scope}/${short}/${short}.log4j.erb"),
    require => File["/etc/${scope}/${short}"],
  }

  file { "/var/log/${scope}/${short}":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => File["/var/log/${scope}"],
  }

  logrotate::rule { $short:
    path         => "/var/log/${scope}/${short}/${short}.log",
    require      => File["/var/log/${scope}/${short}"],
    rotate       => 365,
    rotate_every => 'week',
    compress     => true,
    copytruncate => true,
    missingok    => true,
    ifempty      => true,
    dateext      => true,
    dateformat   => '.%Y-%m-%d'
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${user}/${catname}/webapps/${short}.war": 
    ensure => 'link',
    target => "/var/${scope}/webapps/${short}.war",
#    notify  => Service[$catname],
    require => [File[ "/etc/${scope}/${short}/beans.properties"],Dhrep::Resources::Servicetomcat[$catname]],
  }

  ###
  # crud comment and analyse scrpits
  #
  file { '/opt/dhrep/crud-analyse-script.pl':
    source  => 'puppet:///modules/dhrep/opt/dhrep/crud-analyse-script.pl',
    owner   => $user,
    group   => $group,
    mode    => '0700',
    require => File['/opt/dhrep'],
  }
  file { '/opt/dhrep/crud-comment-script.pl':
    source  => 'puppet:///modules/dhrep/opt/dhrep/crud-comment-script.pl',
    owner   => $user,
    group   => $group,
    mode    => '0700',
    require => [File['/opt/dhrep'],File['/opt/dhrep/crud-analyse-script.pl']],
  }

  ###
  # cron for crud comment and analyse
  ###
  cron { 'crud-comment' :
    command => '/opt/dhrep/crud-comment-script.pl',
    user    => $user,
    hour    => 4,
    minute  => 3,
    require => File['/opt/dhrep/crud-comment-script.pl'],
  }
  cron { 'crud-analyse' :
    command => '/opt/dhrep/crud-analyse-script.pl -l /var/log/textgrid/tgcrud/rollback.log -c /var/log/textgrid/tgcrud/logcomments.log',
    user    => $user,
    minute  => '*/5',
    require => File['/opt/dhrep/crud-analyse-script.pl'],
  }

}
