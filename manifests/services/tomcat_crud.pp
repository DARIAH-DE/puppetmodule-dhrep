# == Class: dhrep::services::tomcat_crud
#
# Class to install and configure dhcrud or tgcrud tomcat.
#
class dhrep::services::tomcat_crud (
  $scope        = undef,
){

  $short        = 'tgcrud'
  $catname      = 'tomcat-tgcrud'
  $http_port    = '9093'
  $control_port = '9008'
  $xmx          = '1024'
  $xms          = '128'
  $jmx_port     = '9993'
  $gid          = '29900'
  $uid          = '49628'
  $template     = "dhrep/etc/default/tomcat.${short}.erb"
  $depcat       = 'wildfly'

  $user         = $scope
  $group        = 'ULSB'

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
    init_dependencies => $depcat,
    require           => Service[$depcat],
  }

}
