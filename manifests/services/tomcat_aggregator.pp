# == Class: dhrep::services::tomcat_aggregator
#
# Class to install and configure aggregator tomcat.
#
class dhrep::services::tomcat_aggregator (
  $scope        = undef,
){

  $catname      = 'tomcat-aggregator'
  $http_port    = '9095'
  $control_port = '9010'
  $xmx          = '1024'
  $xms          = '128'
  $jmx_port     = '9995'
  $gid          = '1014'
  $uid          = '1014'
  $template     = 'dhrep/etc/default/tomcat-java7.erb'

  $user         = $catname
  $group        = $catname

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
