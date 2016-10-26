# == Class: dhrep::services::digilib
#
# Class to install and configure digilib
#
class dhrep::services::digilib (
  $scope   = undef,
  $version = 'latest',
) inherits dhrep::params {

  include dhrep::services::tomcat_digilib

  $_confdir   = $::dhrep::params::confdir
  $_vardir    = $::dhrep::params::vardir
  $_catname   = $::dhrep::services::tomcat_digilib::catname
  $_user      = $::dhrep::services::tomcat_digilib::user
  $_group     = $::dhrep::services::tomcat_digilib::group
  $_http_port = $::dhrep::services::tomcat_digilib::http_port
  $_jmx_port  = $::dhrep::services::tomcat_digilib::jmx_port

  # FIXME remove if textgrid services finally are deployed to /var/dhrep/webapps!
  if $scope == 'textgrid' {
    $_aptdir = '/var/textgrid/webapps'
  }
  else {
    $_aptdir = $::dhrep::params::aptdir
  }

  $templates  = "dhrep/etc/dhrep/digilib/"

  ###
  # update apt repo and install package
  ###
  package {
    'libvips37': ensure        => present; # this is needed by the prescaler, see dhrep::services::intern::messaging
    'libvips-tools': ensure    => present;
    'digilib-service': ensure  => $version,
                       require => [Exec['update_dariah_apt_repository'],Dhrep::Resources::Servicetomcat[$_catname]],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_user}/${_catname}/webapps/digilibservice":
    ensure  => 'link',
    target  => "${_aptdir}/digilibservice",
    require => [Dhrep::Resources::Servicetomcat[$_catname], Package["digilib-service"]],
  }

  ###
  # config
  ###
  file { "${_confdir}/digilib":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { "${_confdir}/digilib/digilib.properties":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${templates}/digilib.properties.erb"),
    require => File["${_confdir}/digilib"],
    notify  => Service[$_catname],
  }
  file { "${_confdir}/digilib/digilib-service.properties":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${templates}/digilib-service.properties.erb"),
    require => File["${_confdir}/digilib"],
    notify  => Service[$_catname],
  }

  ###
  # data
  ###
  file { "${_vardir}/digilib":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  # the prescale images will be written by wildfly
  file { "${_vardir}/digilib/prescale":
    ensure  => directory,
    owner   => 'wildfly',
    group   => 'wildfly',
    mode    => '0755',
    require => File["${_vardir}/digilib"],
  }

  ###
  # copy config file
  ###
  file { "/home/${_user}/${_catname}/webapps/digilibservice/WEB-INF/classes/digilib.properties":
    source  => "${_confdir}/digilib/digilib.properties",
    require => [File["/home/${_user}/${_catname}/webapps/digilibservice"],File["${_confdir}/digilib/digilib.properties"]],
  }
  file { "/home/${_user}/${_catname}/webapps/digilibservice/WEB-INF/classes/digilib-service.properties":
    source  => "${_confdir}/digilib/digilib-service.properties",
    require => [File["/home/${_user}/${_catname}/webapps/digilibservice"],File["${_confdir}/digilib/digilib-service.properties"]],
  }

  ###
  # nrpe
  ###
  dariahcommon::nagios_service { 'check_http_digilib':
    command => "/usr/lib/nagios/plugins/check_http -H localhost -t 30 -p ${_http_port} -u /digilibservice/rest/info -s \"Digilib\"",
  }
  dariahcommon::nagios_service { 'check_jmx_digilib_heap_used':
    command => "/usr/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port}/jmxrmi -O java.lang:type=Memory -A HeapMemoryUsage -K used -I HeapMemoryUsage -J used -w 1800000000 -c 2000000000",
  }
  dariahcommon::nagios_service { 'check_jmx_digilib_thread_count':
    command => "/usr/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port}/jmxrmi -O java.lang:type=Threading -A ThreadCount",
  }
  dariahcommon::nagios_service { 'check_jmx_digilib_process_cpu_load':
    command => "/usr/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port}/jmxrmi -O java.lang:type=OperatingSystem -A ProcessCpuLoad",
  }
  dariahcommon::nagios_service { 'check_jmx_digilib_open_fd':
    command => "/usr/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port}/jmxrmi -O java.lang:type=OperatingSystem -A OpenFileDescriptorCount",
  }
}
