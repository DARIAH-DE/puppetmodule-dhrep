# == Class: dhrep::tools
#
# Class for tools, yeah!
#
class dhrep::tools {

  package {
    'wget': ensure => present;
  }

  ###
  # misc files
  ###
  file { '/usr/local/bin/wait_for_url_ready.sh':
    mode   => '0744',
    source => 'puppet:///modules/dhrep/tools/wait_for_url_ready.sh',
  }

  ###
  # cron nrpe check
  ###
  nrpe::plugin { 'check_cron':
    plugin => 'check_procs',
    args   => '-c 1:20 -w 1:2 -C cron',
  }

  ###
  # tsm nrpe check
  ###
  file { '/var/log/tsm/dsmerror.log':
    group => 'nagios',
    mode  => '0660',
  }
  file { '/usr/lib/nagios/plugins/check_tivoli':
    ensure => file,
    source => 'puppet:///modules/dhrep/usr/lib/nagios/plugins/check_tivoli',
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  nrpe::plugin { 'check_tivoli_root':
    plugin => 'check_tivoli',
    args   => '-c /',
	 command_prefix = 'sudo',
  }
}
