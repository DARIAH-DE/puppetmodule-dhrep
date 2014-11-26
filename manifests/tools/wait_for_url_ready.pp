# == Define: textgrid::tools::wait_for_url_ready
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
define textgrid::tools::wait_for_url_ready (
  $url,
  $retries = 20,
  $refreshonly = false,
) {

  require textgrid::tools

  exec {"wait_for_url_ready_${name}":
    path        => ['/usr/bin','/bin','/usr/sbin', '/usr/local/bin'],
    command     => "/usr/local/bin/wait_for_url_ready.sh ${url} ${retries} ",
    refreshonly => $refreshonly,
#    logoutput => true,
  }

}
