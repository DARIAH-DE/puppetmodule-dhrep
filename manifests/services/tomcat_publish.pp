# == Class: dhrep::services::tomcat_publish
#
# Class to install and configure tgpublish or dhpublish tomcat.
#
class dhrep::services::tomcat_publish (
){

  $scope        = 'textgrid'
  $short        = 'tgpublish'
  $catname      = 'tomcat-tgpublish'
  $depcat       = 'tomcat-tgcrud'
  $http_port    = '9094'
  $control_port = '9009'
  $xmx          = '1024'
  $xms          = '128'
  $jmx_port     = '9994'
  $gid          = '29900'
  $uid          = '49628'
  $template     = "${scope}/etc/default/tomcat.${short}.erb"

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
