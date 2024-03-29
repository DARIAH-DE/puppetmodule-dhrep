# == Class: dhrep::services::tomcat_digilib2
#
# Class to install and configure second digilib tomcat.
#
class dhrep::services::tomcat_digilib2 (
  $scope = undef,
  $xmx   = $::dhrep::params::tomcat_digilib_xmx,
  $xms   = $::dhrep::params::tomcat_digilib_xms,
  $check_uri = 'textgrid:wtxq.0',
) inherits dhrep::params {

  $catname      = $::dhrep::params::config['tomcat_digilib2']['catname']
  $http_port    = $::dhrep::params::config['tomcat_digilib2']['http_port']
  $control_port = $::dhrep::params::config['tomcat_digilib2']['control_port']
  $jmx_port     = $::dhrep::params::config['tomcat_digilib2']['jmx_port']
  # digilib2 should run with same user as digilib
  $uid          = $::dhrep::params::config['tomcat_digilib']['uid']
  $gid          = $::dhrep::params::config['tomcat_digilib']['gid']
  $user         = $::dhrep::params::config['tomcat_digilib']['catname']
  $depcat       = 'tomcat-crud'
  $check_url    = "http://localhost:${::dhrep::params::config['tomcat_digilib2']['http_port']}/digilibservice/rest/IIIF/${check_uri}/info.json"


  ###
  # user, home-dir and user-tomcat
  ###
  usertomcat::instance { $catname:
    user               => $user,
    group              => $user,
    uid                => $uid,
    gid                => $gid,
    http_port          => $http_port,
    control_port       => $control_port,
    jmx_port           => $jmx_port,
    init_dependencies  => $depcat,
    xmx                => $xmx,
    xms                => $xms,
    telegraf_enabled   => true,
    tomcat_version     => $dhrep::params::tomcat_version,
    initd_template_loc => 'dhrep/etc/init.d/tomcat8-digilib2.Debian.erb',
  }
}
