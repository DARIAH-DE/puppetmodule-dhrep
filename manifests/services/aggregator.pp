# == Class: dhrep::services::aggregator
#
# Class to install and configure aggregator
#
class dhrep::services::aggregator (
  $scope   = undef,
  $version = 'latest',
) inherits dhrep::params {

  include dhrep::services::tomcat_aggregator

  $_confdir   = $::dhrep::params::confdir
  $_catname   = $::dhrep::services::tomcat_aggregator::catname
  $_user      = $::dhrep::services::tomcat_aggregator::user
  $_group     = $::dhrep::services::tomcat_aggregator::group
  $_http_port = $::dhrep::services::tomcat_aggregator::http_port
  $_jmx_port  = $::dhrep::services::tomcat_aggregator::jmx_port
  $templates  = "dhrep/etc/dhrep/aggregator"

  # FIXME remove if textgrid services finally are deployed to /var/dhrep/webapps!
  if $scope == 'textgrid' {
    $_aptdir = '/var/textgrid/webapps'
  }
  else {
    $_aptdir = $::dhrep::params::aptdir
  }

  package { 'aggregator':
    ensure  => $version,
    require => [Exec['update_dariah_apt_repository'],Dhrep::Resources::Servicetomcat[$_catname]],
  }

  ###
  # config
  ###
  file { "${_confdir}/aggregator":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { "${_confdir}/aggregator/aggregator.properties":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${templates}/aggregator.properties.erb"),
    require =>  File["${_confdir}/aggregator"],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_user}/${_catname}/webapps/aggregator":
    ensure  => 'link',
    target  => "${_aptdir}/aggregator",
    require => [File["${_confdir}/aggregator/aggregator.properties"],Dhrep::Resources::Servicetomcat[$_catname]],
  }

  ###
  # nrpe for aggregator
  ###
  file { '/etc/nagios-plugins/config/jmx.cfg':
    source  => 'puppet:///modules/dhrep/etc/nagios-plugins/config/jmx.cfg',
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Class[dariahcommon::nagios],
  }
  file { '/usr/lib/nagios/plugins/check_jmx.jar':
    source  => 'puppet:///modules/dhrep/usr/lib/nagios/plugins/check_jmx.jar',
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Class[dariahcommon::nagios],
  }
  file { '/usr/lib/nagios/plugins/check_jmx':
    source  => 'puppet:///modules/dhrep/usr/lib/nagios/plugins/check_jmx',
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/usr/lib/nagios/plugins/check_jmx.jar'],
  }
  dariahcommon::nagios_service { 'check_http_aggregator':
    command => "/usr/lib/nagios/plugins/check_http -H localhost -t 30 -p ${_http_port} -u /aggregator/version -s \"Aggregator\"",
  }
  dariahcommon::nagios_service { 'check_jmx_aggregator_heap_used':
    command => "/usr/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_dir}/jmxrmi -O java.lang:type=Memory -A HeapMemoryUsage -K used -I HeapMemoryUsage -J used -w 900000000 -c 1000000000",
  }
  dariahcommon::nagios_service { 'check_jmx_aggregator_thread_count':
    command => "/usr/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_dir}/jmxrmi -O java.lang:type=Threading -A ThreadCount",
  }
  dariahcommon::nagios_service { 'check_jmx_aggregator_process_cpu_load':
    command => "/usr/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_dir}/jmxrmi -O java.lang:type=OperatingSystem -A ProcessCpuLoad",
  }
  dariahcommon::nagios_service { 'check_jmx_aggregator_open_fd':
    command => "/usr/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_dir}/jmxrmi -O java.lang:type=OperatingSystem -A OpenFileDescriptorCount",
  }
  dariahcommon::nagios_service { 'check_jmx_aggregator_avg_response':
    command => "/usr/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_dir}/jmxrmi -O 'org.apache.cxf:bus.id=aggregator,type=Performance.Counter.Server,service=\"{http://aggregator.services.textgrid.info/}REST\",port=\"REST\"' -A AvgResponseTime",
  }
  dariahcommon::nagios_service { 'check_jmx_aggregator_avg_response_html':
    command => "/usr/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_dir}/jmxrmi -O 'org.apache.cxf:bus.id=aggregator,type=Performance.Counter.Server,service=\"{http://aggregator.services.textgrid.info/}REST\",port=\"REST\",operation=\"getHTML\"' -A AvgResponseTime",
  }
}
