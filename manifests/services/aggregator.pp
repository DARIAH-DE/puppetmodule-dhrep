# Class to install and configure aggregator
#
class dhrep::services::aggregator (
  $scope   = undef,
  $version = 'latest',
) inherits dhrep::params {

  include dhrep::services::tomcat_aggregator

  $_confdir   = $::dhrep::params::confdir
  $_catname   = $::dhrep::services::tomcat_aggregator::catname
  $_http_port = $::dhrep::services::tomcat_aggregator::http_port
  $_jmx_port  = $::dhrep::services::tomcat_aggregator::jmx_port
  $templates  = "dhrep/etc/dhrep/aggregator"

  # FIXME remove if textgrid services finally are deployed to /var/dhrep/webapps!
  if $scope == 'textgrid' {
    $_aptdir = '/var/textgrid/webapps'

    ### FIXME remove link if we dont need it anymore!
    file { '/etc/textgrid/':
      ensure  => directory,
      owner   => root,
      group   => root,
      mode    => '0644',
    }
  }
  else {
    $_aptdir = $::dhrep::params::aptdir
  }

  package { 'aggregator':
    ensure  => $version,
    require => [Exec['update_dariah_apt_repository'],Usertomcat::Instance[$_catname]],
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
  # remove symlink if service has been deployed with new beans.xml
  file { '/etc/textgrid/aggregator':
    ensure => link,
    target => "${_confdir}/aggregator",
    require => File['/etc/textgrid'],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_catname}/${_catname}/webapps/aggregator":
    ensure  => 'link',
    target  => "${_aptdir}/aggregator",
    require => [File["${_confdir}/aggregator/aggregator.properties"],Usertomcat::Instance[$_catname]],
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
  }
  file { '/usr/lib/nagios/plugins/check_jmx.jar':
    source  => 'puppet:///modules/dhrep/usr/lib/nagios/plugins/check_jmx.jar',
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }
  file { '/usr/lib/nagios/plugins/check_jmx':
    source  => 'puppet:///modules/dhrep/usr/lib/nagios/plugins/check_jmx',
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }
  nrpe::plugin { 'check_http_aggregator':
    plugin => 'check_http',
    args   => "-H localhost -t 30 -p ${_http_port} -u /aggregator/version -s \"Aggregator\"",
  }
  nrpe::plugin { 'check_jmx_aggregator_heap_used':
    plugin => 'check_jmx',
    args   => "-U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port}/jmxrmi -O java.lang:type=Memory -A HeapMemoryUsage -K used -I HeapMemoryUsage -J used -w 900000000 -c 1000000000",
  }
  nrpe::plugin { 'check_jmx_aggregator_thread_count':
    plugin => 'check_jmx',
    args   => "-U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port}/jmxrmi -O java.lang:type=Threading -A ThreadCount",
  }
  nrpe::plugin { 'check_jmx_aggregator_process_cpu_load':
    plugin => 'check_jmx',
    args   => "-U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port}/jmxrmi -O java.lang:type=OperatingSystem -A ProcessCpuLoad",
  }
  nrpe::plugin { 'check_jmx_aggregator_open_fd':
    plugin => 'check_jmx',
    args   => "-U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port}/jmxrmi -O java.lang:type=OperatingSystem -A OpenFileDescriptorCount",
  }
  nrpe::plugin { 'check_jmx_aggregator_avg_response':
    plugin => 'check_jmx',
    args   => "-U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port}/jmxrmi -O 'org.apache.cxf:bus.id=aggregator,type=Performance.Counter.Server,service=\"{http://aggregator.services.textgrid.info/}REST\",port=\"REST\"' -A AvgResponseTime",
  }
  nrpe::plugin { 'check_jmx_aggregator_avg_response_html':
    plugin => 'check_jmx',
    args   => "-U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port}/jmxrmi -O 'org.apache.cxf:bus.id=aggregator,type=Performance.Counter.Server,service=\"{http://aggregator.services.textgrid.info/}REST\",port=\"REST\",operation=\"getHTML\"' -A AvgResponseTime",
  }

  ###
  # metrics
  ###
  telegraf::input { "jolokia_${_catname}_avg-response":
    plugin_type => 'jolokia',
    options     => {
      'context' => '/jolokia/',
    },
    sections    => {
      'jolokia.servers' => {
        'name'   => $_catname,
        'host' => '127.0.0.1',
        'port' => $_http_port,
      },
      'jolokia.metrics' => {
        'name' => 'cxf_avg_response',
        'mbean' => 'org.apache.cxf:bus.id=aggregator,type=Performance.Counter.Server,service=\"{http://aggregator.services.textgrid.info/}REST\",port=\"REST\"',
        'attribute' => 'AvgResponseTime',
      },
    },
  }
  telegraf::input { "jolokia_${_catname}_min-response":
    plugin_type => 'jolokia',
    options     => {
      'context' => '/jolokia/',
    },
    sections    => {
      'jolokia.servers' => {
        'name'   => $_catname,
        'host' => '127.0.0.1',
        'port' => $_http_port,
      },
      'jolokia.metrics' => {
        'name' => 'cxf_min_response',
        'mbean' => 'org.apache.cxf:bus.id=aggregator,type=Performance.Counter.Server,service=\"{http://aggregator.services.textgrid.info/}REST\",port=\"REST\"',
        'attribute' => 'MinResponseTime',
      },
    },
  }
  telegraf::input { "jolokia_${_catname}_max-response":
    plugin_type => 'jolokia',
    options     => {
      'context' => '/jolokia/',
    },
    sections    => {
      'jolokia.servers' => {
        'name'   => $_catname,
        'host' => '127.0.0.1',
        'port' => $_http_port,
      },
      'jolokia.metrics' => {
        'name' => 'cxf_max_response',
        'mbean' => 'org.apache.cxf:bus.id=aggregator,type=Performance.Counter.Server,service=\"{http://aggregator.services.textgrid.info/}REST\",port=\"REST\"',
        'attribute' => 'MaxResponseTime',
      },
    },
  }

}
