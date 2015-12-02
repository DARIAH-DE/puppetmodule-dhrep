# == Define: dhrep::resources::servicetomcat
#
# Create a new user and tomcat-home and add tomcat-user-instance
# uses debian package tomcat7-user
#
# === Parameters
#
# [*gid*]
#   the group id of new user
#
# [*uid*]
#   the user id of new user
#
# [*http_port*]
#   which port should tomcat listen on
#
# [*control_port*]
#   the tomcat control port
#
# [*jmx_port*]
#   port for java jmx management
#
# [*xmx*]
#   java max memory allocation (Xmx), in megabyte, default: 1024
#
# [*xms*]
#   java inital memory allocation (Xms), in megabyte, default: 128
#
# [*user*]
#   user which the service belongs to (will be created), defaults to $name if not set 
#
# [*group*]
#   usergroup which the service belongs to (will be created), defaults to $name if not set 
#
# [*defaults_template*]
#   defaults file template for /etc/defaults, if different from dhrep/etc/default/tomcat.erb
#
# [*init_dependencies*]
#   services which should be started before this tomcat, added as dependency to init.d script, separate with whitespace if more than one
#
# TODO:
#   install libapr1 and integrate with tomcat-conf
#      in conf/server.conf
#   <!--APR library loader. Documentation at /docs/apr.html -->
#   <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />
#
define dhrep::resources::servicetomcat (
  $gid,
  $uid,
  $http_port,
  $control_port,
  $jmx_port,
  $xmx               = 1024,
  $xms               = 128,
  $group             = $name,
  $user              = $name,
  $defaults_template = 'dhrep/etc/default/tomcat.erb',
  $init_dependencies = '',
){

  require dhrep::tools

  # Check if group and user are already existing.
  # Just in case we have two tomcats using the same user and group
  # (e.g. tgcrud and tgcrud-public)
  if ! defined(Group[$group]) {
    group { $group:
      ensure =>  present,
      gid    =>  $gid,
    }
  }
  if ! defined(User[$user]) {
    user { $user:
      ensure     => present,
      uid        => $uid,
      gid        => $gid,
      shell      => '/bin/bash',
      home       => "/home/${user}",
      managehome => true,
    }
  }

  exec { "create_${name}":
    path    => ['/usr/bin','/bin','/usr/sbin'],
    command => "tomcat7-instance-create -p ${http_port} -c ${control_port} /home/${user}/${name}",
    creates => "/home/${user}/${name}",
    user    => $user,
    require => Package['tomcat7-user'],
  }
  ~>
  exec { "patching_${name}_for_apr":
    path        => ['/usr/bin','/bin','/usr/sbin'],
    command     => "patch /home/${user}/${name}/conf/server.xml < /usr/local/src/tomcat-apr.patch",
    refreshonly => true,
    require     => File['/usr/local/src/tomcat-apr.patch'],
  }

  file { "/etc/init.d/${name}":
    ensure  => present,
    content => template('dhrep/etc/init.d/tomcat.Debian.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    before  => Service[$name],
    notify  => Service[$name],
  }

  file { "/etc/default/${name}":
    ensure  => present,
    content => template($defaults_template),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    before  => Service[$name],
    notify  => Service[$name],
  }

  service { $name:
    ensure  => running,
    enable  => true,
    require => Exec["create_${name}"],
  }

  logrotate::rule { $name:
    path         => "/home/${user}/${name}/logs/catalina.out",
    require      => Exec["create_${name}"],
    rotate       => 365,
    rotate_every => 'week',
    compress     => true,
    copytruncate => true,
    missingok    => true,
    ifempty      => true,
    dateext      => true,
    dateformat   => '.%Y-%m-%d'
  }

}
