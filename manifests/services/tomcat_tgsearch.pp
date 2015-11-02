# == Class: dhrep::services::tomcat_tgsearch
#
# Class to install and configure tgsearch tomcat.
#
class dhrep::services::tomcat_tgsearch (
  $scope        = undef,
){

  $catname      = 'tomcat-tgsearch'
  $http_port    = '9090'
  $control_port = '9005'
  $xmx          = '1024'
  $xms          = '128'
  $jmx_port     = '9990'
  $gid          = '1007'
  $uid          = '1007'
  $template     = 'dhrep/etc/default/tomcat.erb'
  
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
