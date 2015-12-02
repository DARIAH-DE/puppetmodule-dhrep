class dhrep::tools {

  ###
  # misc files
  ###
  file { "/usr/local/bin/wait_for_url_ready.sh":
    mode    => '0744',
    source  => 'puppet:///modules/dhrep/tools/wait_for_url_ready.sh',
  }

  file { "/usr/local/src/tomcat-apr.patch":
    source => 'puppet:///modules/dhrep/tools/tomcat-apr.patch'
  }

  ###
  # misc nrpe checks
  ###
  dariahcommon::nagios_service { 'check_cron':
    command => "/usr/lib/nagios/plugins/check_procs -c 1:20 -w 1:2 -C cron",
  }

  file { '/usr/lib/nagios/plugins/check_tivoli':
    source  => 'puppet:///modules/dhrep/usr/lib/nagios/plugins/check_tivoli',
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0755',
#    require => Class[dariahcommon::nagios],
  }
  dariahcommon::nagios_service { 'check_tivoli_root':
    command => "/usr/lib/nagios/plugins/check_tivoli -c /",
    require => File['/usr/lib/nagios/plugins/check_tivoli'],
  }

}
