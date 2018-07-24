# == Class: dhrep::services::digilib
#
# Class to install and configure digilib
#
class dhrep::services::digilib (
  $scope   = undef,
  $version = 'latest',
  $prescale_location = undef,
  $tgcrud_location = 'https://textgridlab.org/1.0/tgcrud/TGCrudService?wsdl',
  $dhcrud_location = 'https://repository.de.dariah.eu/1.0/dhcrud/',
) inherits dhrep::params {

  include dhrep::services::tomcat_digilib
  include dhrep::services::tomcat_digilib2

  $_confdir    = $::dhrep::params::confdir
  $_vardir     = $::dhrep::params::vardir
  $_catname    = $::dhrep::services::tomcat_digilib::catname
  $_xmx        = $::dhrep::services::tomcat_digilib::xmx
  $_http_port  = $::dhrep::services::tomcat_digilib::http_port
  $_jmx_port   = $::dhrep::services::tomcat_digilib::jmx_port
  $_http_port2 = $::dhrep::services::tomcat_digilib2::http_port
  $_jmx_port2  = $::dhrep::services::tomcat_digilib2::jmx_port
  $_aptdir     = $::dhrep::params::aptdir
  $templates   = 'dhrep/etc/dhrep/digilib/'

  ###
  # update apt repo and install package
  ###
  package {
    'libvips37': ensure        => present; # this is needed by the prescaler, see dhrep::services::intern::messaging
    'libvips-tools': ensure    => present;
    'digilib-service': ensure  => $version,
    require                    => [Exec['update_dariah_apt_repository'],Usertomcat::Instance[$_catname]],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_catname}/${_catname}/webapps/digilibservice":
    ensure  => 'link',
    target  => "${_aptdir}/digilibservice",
    require => [Usertomcat::Instance[$_catname], Package['digilib-service']],
  }
  file { "/home/${_catname}/${_catname}2/webapps/digilibservice":
    ensure  => 'link',
    target  => "${_aptdir}/digilibservice",
    require => [Usertomcat::Instance['tomcat-digilib2'], Package['digilib-service']],
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
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${templates}/digilib.properties.erb"),
    require => File["${_confdir}/digilib"],
    notify  => Service[$_catname],
  }
  file { "${_confdir}/digilib/digilib-service.properties":
    ensure  => file,
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
  if($prescale_location) {
    # create link to external prescale-dir, e.g. on nfs mount
    file { "${_vardir}/digilib/prescale":
      ensure => 'link',
      target => $prescale_location,
    }
  } else {
    # create local prescale dir
    # the prescale images will be written by wildfly
    file { "${_vardir}/digilib/prescale":
      ensure  => directory,
      owner   => 'wildfly',
      group   => 'wildfly',
      mode    => '0755',
      require => File["${_vardir}/digilib"],
    }
  }
  # symlink to old data path if scope=textgrid
#  if $scope == 'textgrid' {
#    file { '/var/textgrid/digilib/':
#      ensure => link,
#      target => "${_vardir}/digilib/",
#    }
#  }

  ###
  # copy config file
  ###
  file { "/home/${_catname}/${_catname}/webapps/digilibservice/WEB-INF/classes/digilib.properties":
    source  => "${_confdir}/digilib/digilib.properties",
    require => [File["/home/${_catname}/${_catname}/webapps/digilibservice"],File["${_confdir}/digilib/digilib.properties"]],
  }
  file { "/home/${_catname}/${_catname}/webapps/digilibservice/WEB-INF/classes/digilib-service.properties":
    source  => "${_confdir}/digilib/digilib-service.properties",
    require => [File["/home/${_catname}/${_catname}/webapps/digilibservice"],File["${_confdir}/digilib/digilib-service.properties"]],
  }
  file { "/home/${_catname}/${_catname}2/webapps/digilibservice/WEB-INF/classes/digilib.properties":
    source  => "${_confdir}/digilib/digilib.properties",
    require => [File["/home/${_catname}/${_catname}2/webapps/digilibservice"],File["${_confdir}/digilib/digilib.properties"]],
  }
  file { "/home/${_catname}/${_catname}2/webapps/digilibservice/WEB-INF/classes/digilib-service.properties":
    source  => "${_confdir}/digilib/digilib-service.properties",
    require => [File["/home/${_catname}/${_catname}2/webapps/digilibservice"],File["${_confdir}/digilib/digilib-service.properties"]],
  }

  ###
  # nginx upstream conf for digilib
  ###
  file { '/etc/nginx/conf.d/digilib.conf':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('dhrep/etc/dhrep/nginx/conf.d/digilib.conf.erb'),
    notify  => Service['nginx'],
  }

  ###
  # restart both digilib-tomcats every day at a different time
  ###
  cron { 'restart-tomcat-digilib':
    command => 'service tomcat-digilib restart &> /dev/null',
    user    => 'root',
    hour    => ['1' ,'13'],
    minute  => '0',
  }
  cron { 'restart-tomcat-digilib2':
    command => 'service tomcat-digilib2 restart &> /dev/null',
    user    => 'root',
    hour    => ['2','14'],
    minute  => '0',
  }

# calculate critical and warning values from xmx for nrpe
$xmx_in_byte = inline_template("<%
        mem,unit = @_xmx.scan(/\\d+|\\D+/)
        mem = mem.to_f
        case unit
            when nil
              mem *= (1<<0)
            when 'k'
              mem *= (1<<10)
            when 'm'
              mem *= (1<<20)
            when 'g'
              mem *= (1<<30)
        end
        %><%= mem.to_i %>")
  # warn at 85%, crit at 95%
  $mem_warn = inline_template('<%= (@xmx_in_byte.to_f * 0.85 ).to_i %>')
  $mem_crit = inline_template('<%= (@xmx_in_byte.to_f * 0.95 ).to_i %>')

  ###
  # nrpe digilib
  ###
  nrpe::plugin { 'check_http_digilib':
    plugin => 'check_http',
    args   => "-H localhost -t 30 -p ${_http_port} -u /digilibservice/rest/info -s \"Digilib\"",
  }
  nrpe::plugin { 'check_jmx_digilib_heap_used':
    plugin => '/check_jmx',
    args   => "-U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port}/jmxrmi -O java.lang:type=Memory -A HeapMemoryUsage -K used -I HeapMemoryUsage -J used -w ${mem_warn} -c ${mem_crit}",
  }
  nrpe::plugin { 'check_jmx_digilib_thread_count':
    plugin => '/check_jmx',
    args   => "-U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port}/jmxrmi -O java.lang:type=Threading -A ThreadCount",
  }
  nrpe::plugin { 'check_jmx_digilib_process_cpu_load':
    plugin => '/check_jmx',
    args   => "-U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port}/jmxrmi -O java.lang:type=OperatingSystem -A ProcessCpuLoad",
  }
  nrpe::plugin { 'check_jmx_digilib_open_fd':
    plugin => '/check_jmx',
    args   => "-U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port}/jmxrmi -O java.lang:type=OperatingSystem -A OpenFileDescriptorCount",
  }
  ###
  # nrpe digilib2
  ###
  nrpe::plugin { 'check_http_digilib2':
    plugin => 'check_http',
    args   => "-H localhost -t 30 -p ${_http_port2} -u /digilibservice/rest/info -s \"Digilib\"",
  }
  nrpe::plugin { 'check_jmx_digilib2_heap_used':
    plugin => '/check_jmx',
    args   => "-U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port2}/jmxrmi -O java.lang:type=Memory -A HeapMemoryUsage -K used -I HeapMemoryUsage -J used -w ${mem_warn} -c ${mem_crit}",
  }
  nrpe::plugin { 'check_jmx_digilib2_thread_count':
    plugin => '/check_jmx',
    args   => "-U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port2}/jmxrmi -O java.lang:type=Threading -A ThreadCount",
  }
  nrpe::plugin { 'check_jmx_digilib2_process_cpu_load':
    plugin => '/check_jmx',
    args   => "-U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port2}/jmxrmi -O java.lang:type=OperatingSystem -A ProcessCpuLoad",
  }
  nrpe::plugin { 'check_jmx_digilib2_open_fd':
    plugin => '/check_jmx',
    args   => "-U service:jmx:rmi:///jndi/rmi://localhost:${_jmx_port2}/jmxrmi -O java.lang:type=OperatingSystem -A OpenFileDescriptorCount",
  }
}
