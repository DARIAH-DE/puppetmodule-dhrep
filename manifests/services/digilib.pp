# == Class: dhrep::services::digilib
#
# Class to install and configure digilib
#
class dhrep::services::digilib (
  $scope            = undef,
  $short            = 'digilibservice',
  $digilib_name     = 'digilib-service',
  $digilib_version  = 'latest',
){

  include dhrep::services::tomcat_digilib

  $catname   = $dhrep::services::tomcat_digilib::catname
  $user      = $dhrep::services::tomcat_digilib::user
  $group     = $dhrep::services::tomcat_digilib::group
  $http_port = $dhrep::services::tomcat_digilib::http_port

  package {
    'libvips37':     ensure  => present; # this is needed by the prescaler, see dhrep::services::intern::messaging
    'libvips-tools': ensure  => present;
    $digilib_name:   ensure  => $digilib_version, 
                     require => [Exec['update_dariah_apt_repository'],Dhrep::Resources::Servicetomcat[$catname]],
  }

  ###
  # config
  ###

  file { '/etc/textgrid/digilib':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { '/etc/textgrid/digilib/digilib.properties':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/etc/textgrid/digilib/digilib.properties.erb'),
    require => File['/etc/textgrid/digilib'],
    notify  => Service['tomcat-digilib'],
  }

  file { '/etc/textgrid/digilib/digilib-service.properties':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/etc/textgrid/digilib/digilib-service.properties.erb'),
    require => File['/etc/textgrid/digilib'],
    notify  => Service['tomcat-digilib'],
  }

  ###
  # data
  ###

  file { '/var/textgrid/digilib':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  # the prescale images will be written by wildfly
  file { '/var/textgrid/digilib/prescale':
    ensure => directory,
    owner  => 'wildfly',
    group  => 'wildfly',
    mode   => '0755',
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###

  file { "/home/${user}/${catname}/webapps/${short}": 
    ensure  => 'link',
    target  => "/var/${scope}/webapps/${short}",
    require => [Dhrep::Resources::Servicetomcat[$catname], Package[$digilib_name]],
  } 
  ->
  file { "/home/${catname}/${catname}/webapps/digilibservice/WEB-INF/classes/digilib.properties":
#    ensure  => link,
#    target  => '/etc/textgrid/digilib/digilib.properties',
    # dilib doesn't like to load from symlinked files, TODO: still put to etc?
    source => '/etc/textgrid/digilib/digilib.properties',
  } 
  ->
  file { "/home/${catname}/${catname}/webapps/digilibservice/WEB-INF/classes/digilib-service.properties":
#    ensure  => link,
#    target  => '/etc/textgrid/digilib/digilib-service.properties',
    # dilib doesn't like to load from symlinked files, TODO: still put to etc?
    source => '/etc/textgrid/digilib/digilib-service.properties',
  }


  ###
  # nrpe
  ###
  dariahcommon::nagios_service { 'check_http_digilib':
    command => "/usr/lib/nagios/plugins/check_http -H localhost -t 30 -p 9092 -u /digilibservice/rest/info -s \"Digilib\"",
  }
  dariahcommon::nagios_service { 'check_jmx_digilib_heap_used':
    command => "/usr/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:9992/jmxrmi -O java.lang:type=Memory -A HeapMemoryUsage -K used -I HeapMemoryUsage -J used -w 1800000000 -c 2000000000",
  }
# no perm gen in java8!
#  dariahcommon::nagios_service { 'check_jmx_digilib_permgen':
#    command => "/usr/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:9992/jmxrmi -O \"java.lang:type=MemoryPool,name=CMS Perm Gen\" -A Usage -K used",
#  }
  dariahcommon::nagios_service { 'check_jmx_digilib_thread_count':
    command => "/usr/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:9992/jmxrmi -O java.lang:type=Threading -A ThreadCount",
  }
  dariahcommon::nagios_service { 'check_jmx_digilib_process_cpu_load':
    command => "/usr/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:9992/jmxrmi -O java.lang:type=OperatingSystem -A ProcessCpuLoad",
  }
  dariahcommon::nagios_service { 'check_jmx_digilib_open_fd':
    command => "/usr/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:9992/jmxrmi -O java.lang:type=OperatingSystem -A OpenFileDescriptorCount",
  }

}
