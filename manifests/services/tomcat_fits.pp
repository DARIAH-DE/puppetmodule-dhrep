# == Class: dhrep::services::tomcat_fits
#
# Class to install and configure the fits' tomcat.
#
class dhrep::services::tomcat_fits (
  $scope = undef,
  $xmx   = $::dhrep::params::tomcat_fits_xmx,
  $xms   = $::dhrep::params::tomcat_fits_xms,
) inherits dhrep::params {

  $_logdir      = $::dhrep::params::logdir

  $catname      = $::dhrep::params::config['tomcat_fits']['catname']
  $http_port    = $::dhrep::params::config['tomcat_fits']['http_port']
  $control_port = $::dhrep::params::config['tomcat_fits']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_fits']['jmx_port']
  $user         = $::dhrep::params::config['tomcat_fits']['user']
  $group        = $::dhrep::params::config['tomcat_fits']['group']
  $uid          = $::dhrep::params::config['tomcat_fits']['uid']
  $gid          = $::dhrep::params::config['tomcat_fits']['gid']

  ###
  # user, home-dir and user-tomcat
  ###
  usertomcat::instance { $catname:
    user             => $user,
    group            => $group,
    uid              => $uid,
    gid              => $gid,
    http_port        => $http_port,
    control_port     => $control_port,
    jmx_port         => $jmx_port,
    xmx              => $xmx,
    xms              => $xms,
    telegraf_enabled => true,
    # tomcat's logging now goes directly to /var/log/dhrep, for not having that one backupped (/var/log is currently not being stored by tsm client)
    # FIXME do check!
    #logdir           => "${_logdir}/${catname}",
    tomcat_version   => $dhrep::params::tomcat_version,
  }
}
