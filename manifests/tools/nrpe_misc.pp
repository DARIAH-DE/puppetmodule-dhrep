define dhrep::tools::nrpe_misc(
){

  ###
  # misc nrpe checks
  ###
  dariahcommon::nagios_service { 'check_apt':
    command => "/usr/lib/nagios/plugins/check_apt",
  }
  dariahcommon::nagios_service { 'check_cron':
    command => "/usr/lib/nagios/plugins/check_procs -c 1:20 -w 1:2 -C cron",
  }

}
