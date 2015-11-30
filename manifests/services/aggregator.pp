# == Class: dhrep::services::aggregator
#
# Class to install and configure aggregator
#
class dhrep::services::aggregator (
  $scope              = undef,
  $short              = 'aggregator',
  $aggregator_name    = 'aggregator',
  $aggregator_version = 'latest',
){

  include dhrep::services::tomcat_aggregator

  $catname = $dhrep::services::tomcat_aggregator::catname
  $user    = $dhrep::services::tomcat_aggregator::user
  $group   = $dhrep::services::tomcat_aggregator::group

  package { $aggregator_name:
    ensure  => $aggregator_version,
    require => [Exec['update_dariah_apt_repository'],Dhrep::Resources::Servicetomcat[$catname]],
  }

  ###
  # config
  ###

  file { "/etc/${scope}/aggregator":
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { "/etc/${scope}/${short}/aggregator.properties":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("dhrep/etc/textgrid/${short}/aggregator.properties.erb"),
    require =>  File["/etc/${scope}/${short}"],
  }

  # symlink war from deb package to tomcat webapps dir
  file { "/home/${user}/${catname}/webapps/${short}.war": 
    ensure  => 'link',
    target  => "/var/${scope}/webapps/${short}.war",
#    notify  => Service[$catname],
    require => [File["/etc/${scope}/${short}/aggregator.properties"],Dhrep::Resources::Servicetomcat[$catname]],
  }

  ###
  # nrpe for aggregator
  ###
  dariahcommon::nagios_service { 'check_http_aggregator':
    command => '/usr/lib/nagios/plugins/check_http -H localhost -t 30 -p 9095 -u /aggregator/version -s "Aggregator"',
  }
  dariahcommon::nagios_service { 'check_jmx_aggregator_heap_used':
    command => "/usr/local/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:9995/jmxrmi -O java.lang:type=Memory -A HeapMemoryUsage -K used -I HeapMemoryUsage -J used -w 900000000 -c 1000000000",
  }
  dariahcommon::nagios_service { 'check_jmx_aggregator_permgen':
    command => '/usr/local/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:9995/jmxrmi -O "java.lang:type=MemoryPool,name=CMS Perm Gen" -A Usage -K used',
  }
  dariahcommon::nagios_service { 'check_jmx_aggregator_thread_count':
    command => '/usr/local/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:9995/jmxrmi -O "java.lang:type=Threading" -A ThreadCount',
  }
  dariahcommon::nagios_service { 'check_jmx_aggregator_process_cpu_load':
    command => "/usr/local/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:9995/jmxrmi -O java.lang:type=OperatingSystem -A ProcessCpuLoad",
  }
  dariahcommon::nagios_service { 'check_jmx_aggregator_open_fd':
    command => "/usr/local/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:9995/jmxrmi -O java.lang:type=OperatingSystem -A OpenFileDescriptorCount",
  }
  dariahcommon::nagios_service { 'check_jmx_aggregator_avg_response':
    command => "/usr/local/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:9995/jmxrmi -O 'org.apache.cxf:bus.id=aggregator,type=Performance.Counter.Server,service=\"{http://aggregator.services.textgrid.info/}REST\",port=\"REST\"' -A AvgResponseTime",
  }
  dariahcommon::nagios_service { 'check_jmx_aggregator_avg_response_html':
    command => "/usr/local/lib/nagios/plugins/check_jmx -U service:jmx:rmi:///jndi/rmi://localhost:9995/jmxrmi -O 'org.apache.cxf:bus.id=aggregator,type=Performance.Counter.Server,service=\"{http://aggregator.services.textgrid.info/}REST\",port=\"REST\",operation=\"getHTML\"' -A AvgResponseTime",
  }

}
