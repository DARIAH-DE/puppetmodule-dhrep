# == Class: textgrid::services::pid
#
# Class to install and configure dhpid or tgpid.
#
class textgrid::services::pid (
  $scope           = 'textgrid',
  $short           = 'tgpid',
  $pid_name        = 'tgpid-service',
  $pid_version     = '3.5.2-SNAPSHOT',
  $pid_group       = 'info.textgrid.middleware',
  $pid_user        = '',
  $pid_passwd      = '',
  $pid_endpoint    = 'http://pid.gwdg.de',
  $pid_path        = '/handles/',
  $pid_prefix      = '',
  $pid_responsible = 'TextGrid',
){

  $catname = $textgrid::services::tomcat_publish::catname
  $user    = $textgrid::services::tomcat_publish::scope
  $group   = $textgrid::services::tomcat_publish::group

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
    content => template("${scope}/etc/${scope}/${short}/${short}.properties.erb"),
    require => File["/etc/${scope}/${short}"],
  }

  ###
  # use maven to fetch latest pid service from nexus, copy war, set permissions,
  # and restart tomcat
  ###

  maven { "/var/cache/${scope}/${pid_name}-${pid_version}.war":
    ensure     => latest,
    groupid    => $pid_group,
    artifactid => $pid_name,
    version    => $pid_version,
    packaging  => 'war',
    repos      => ['http://dev.dariah.eu/nexus/content/repositories/snapshots/'],
    require    => Package['maven'],
    notify     => Exec['replace_pid_service'],
  }

  exec { 'replace_pid_service':
    path        => ['/usr/bin','/bin'],
    command     => "/etc/init.d/${catname} stop && rm -rf /home/${scope}/${catname}/webapps/${short} && sleep 2 && cp /var/cache/${scope}/${pid_name}-${pid_version}.war /home/${scope}/${catname}/webapps/${short}.war",
    cwd         => '/root',
    user        => 'root',
    group       => 'root',
    require     => Exec["create_${catname}"],
    refreshonly => true,
  }
  ->
  file {"/home/${scope}/${catname}/webapps/${short}.war":
    group  => $group,
    mode   => '0640',
    notify => Service[$catname],
    require => File["/etc/${scope}/${short}/${short}.properties"],
  }

  ###
  # logging
  ###

  file { "/var/log/${scope}/${short}":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => File["/var/log/${scope}"],
  }

}
