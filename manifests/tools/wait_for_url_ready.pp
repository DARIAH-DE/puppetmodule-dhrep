# == Define: dhrep::tools::wait_for_url_ready
#
# wait for a url to become available, e.g. a war deployed in tomcat
#
# === Parameters
#
# [*url*]
#   the url to wait for
#
# [*retry*]
#   how much retries, till giving up, defaults to 20,
#   there is 1 sec waiting beetween each try
#
# [*refreshonly*]
#   if this script should only run on notification, defaults to false
#
define dhrep::tools::wait_for_url_ready (
  $url,
  $retries     = 30,
  $refreshonly = false,
) {

  require dhrep::tools

  #notify { "${name}_urlwaiting_message":
  #  message => "waiting for at most ${retries} seconds for ${url} to become ready",
  #}
  #->
  exec {"wait_for_url_ready_${name}":
    path        => ['/usr/bin','/bin','/usr/sbin', '/usr/local/bin'],
    command     => "/usr/local/bin/wait_for_url_ready.sh ${url} ${retries}",
    refreshonly => $refreshonly,
    require     => Package['wget'],
#   logoutput   => true,
  }
}
