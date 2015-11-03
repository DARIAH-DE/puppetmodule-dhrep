# == Class: dhrep::services::tgsearch
#
# Class to install and configure tgsearch.
#
class dhrep::services::tgsearch (
  $scope            = 'textgrid',
  $short            = 'tgsearch',
  $tgsearch_name    = 'tgsearch-nonpublic-webapp',
  $tgsearch_version = 'latest',
) {

  package { $tgsearch_name:
    ensure  => $tgsearch_version,
    require => Exec['update_dariah_ubunturepository'],
  }

  include dhrep::services::tomcat_tgsearch

  $catname = $dhrep::services::tomcat_tgsearch::catname
  $user    = $dhrep::services::tomcat_tgsearch::user
  $group   = $dhrep::services::tomcat_tgsearch::group

  ###
  # config
  ###

  file { "/etc/textgrid/${short}":
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0755',
  }

  file { "/etc/textgrid/${short}/tgsearch-nonpublic.properties":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("dhrep/etc/textgrid/${short}/tgsearch.properties.erb"),
    require => File["/etc/textgrid/${short}"],
  }

  file { "/etc/textgrid/${short}/log4j.nonpublic.properties":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("dhrep/etc/textgrid/${short}/log4j.properties.erb"),
    require => File["/etc/textgrid/${short}"],
  }

  file { "/home/${catname}/${catname}/webapps/${short}.war": 
    ensure => 'link',
    target => "/var/${scope}/webapps/tgsearch-nonpublic.war", 
  }

}
