define textgrid::resources::servicetomcat (
  $gid = undef,
  $uid = undef,
  $http_port = undef,
  $control_port = undef,
  $xmx = 1024,
  $xms = 128,
  $jmx_port = undef,
){

  group { $name:
    ensure =>  present,
    gid    =>  $gid,
  }

  user { $name:
    ensure     => present,
    uid        => $uid,
    gid        => $gid,
    shell      => '/bin/bash',
    home       => "/home/${name}",
    managehome => true,
  }

  exec { "create_${name}":
    path    => ['/usr/bin','/bin','/usr/sbin'],
    command => "tomcat7-instance-create -p ${http_port} -c ${control_port} /home/${name}/${name}",
    creates => "/home/${name}/${name}",
    user    => $name,
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
    content => template('textgrid/etc/default/tomcat.erb'),
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
