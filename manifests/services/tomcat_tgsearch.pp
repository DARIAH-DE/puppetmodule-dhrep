# == Class: textgrid::services::tomcat_tgsearch
#
# Class to install and configure tgsearch tomcat.
#
class textgrid::services::tomcat_tgsearch (
){

  $scope        = 'textgrid'
  $catname      = 'tomcat-tgsearch'
  $http_port    = '9090'
  $control_port = '9005'
  $xmx          = '1024'
  $xms          = '128'
  $jmx_port     = '9990'

  $user         = $catname
  $group        = $catname

  ###
  # user, home-dir and user-tomcat
  ###

  textgrid::resources::servicetomcat { $catname:
    user              => $user,
    group             => $group,
    gid               => '1007',
    uid               => '1007',
    http_port         => $http_port,
    control_port      => $control_port,
    jmx_port          => $jmx_port,
    defaults_template => "${scope}/etc/default/tomcat.erb",
  }

}
