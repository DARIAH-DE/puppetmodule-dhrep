# == Class: dhrep::services::tomcat_oaipmh
#
# Class to install and configure oaipmh tomcat.
#
class dhrep::services::tomcat_oaipmh (
  $scope = undef,
  $xmx   = $::dhrep::params::tomcat_oaipmh_xmx,
  $xms   = $::dhrep::params::tomcat_oaipmh_xms,
) inherits dhrep::params {

  $catname      = $::dhrep::params::config['tomcat_oaipmh']['catname']
  $http_port    = $::dhrep::params::config['tomcat_oaipmh']['http_port']
  $control_port = $::dhrep::params::config['tomcat_oaipmh']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_oaipmh']['jmx_port']
  $user         = $::dhrep::params::config['tomcat_oaipmh']['user']
  $group        = $::dhrep::params::config['tomcat_oaipmh']['group']
  $uid          = $::dhrep::params::config['tomcat_oaipmh']['uid']
  $gid          = $::dhrep::params::config['tomcat_oaipmh']['gid']

  ###
  # user, home-dir and user-tomcat
  ###
  usertomcat::create { $catname:
    user              => $user,
    group             => $group,
    uid               => $uid,
    gid               => $gid,
    http_port         => $http_port,
    control_port      => $control_port,
    jmx_port          => $jmx_port,
    xmx               => $xmx,
    xms               => $xms,
    collectd_enabled  => true,
  }
}
