# == Define: textgrid::resources::servicetomcat
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
#   defaults file template for /etc/defaults, if different from textgrid/etc/default/tomcat.erb
#
define textgrid::resources::servicetomcat (
  $gid,
  $uid,
  $http_port,
  $control_port,
  $jmx_port,
  $xmx = 1024,
  $xms = 128,
  $group = $name,
  $user = $name,
  $defaults_template = 'textgrid/etc/default/tomcat.erb',
){

  group { $group:
    ensure =>  present,
    gid    =>  $gid,
  }

  user { $user:
    ensure     => present,
    uid        => $uid,
    gid        => $gid,
    shell      => '/bin/bash',
    home       => "/home/${user}",
    managehome => true,
  }

  exec { "create_${name}":
    path    => ['/usr/bin','/bin','/usr/sbin'],
    command => "tomcat7-instance-create -p ${http_port} -c ${control_port} /home/${user}/${name}",
    creates => "/home/${user}/${name}",
    user    => $user,
    require => Package['tomcat7-user'],
  }

  file { "/etc/init.d/${name}":
    ensure  => present,
    content => template('textgrid/etc/init.d/tomcat.Debian.erb'),
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

}
