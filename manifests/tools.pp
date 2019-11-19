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
}
