# == Class: dhrep::services::tomcat_aggregator
#
# Class to install and configure aggregator tomcat.
#
class dhrep::services::tomcat_aggregator (
  $scope = undef,
) inherits dhrep::params {

  $catname      = $::dhrep::params::config['tomcat_aggregator']['catname']
  $http_port    = $::dhrep::params::config['tomcat_aggregator']['http_port']
  $control_port = $::dhrep::params::config['tomcat_aggregator']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_aggregator']['jmx_port']
  $gid          = $::dhrep::params::config['tomcat_aggregator']['gid']
  $uid          = $::dhrep::params::config['tomcat_aggregator']['uid']
  $user         = $catname
  $group        = $catname
  $template     = 'dhrep/etc/default/tomcat.erb'

  ###
  # user, home-dir and user-tomcat
  ###
  dhrep::resources::servicetomcat { $catname:
    user              => $user,
    group             => $group,
    gid               => $gid,
    uid               => $uid,
    http_port         => $http_port,
    control_port      => $control_port,
    jmx_port          => $jmx_port,
    defaults_template => $template,
  }
}
