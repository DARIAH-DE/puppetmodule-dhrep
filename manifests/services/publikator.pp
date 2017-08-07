# == Class: dhrep::services::publikator
#
# Class to install and configure THE PUBLIKATOR service.
#
class dhrep::services::publikator (
  $scope                     = undef,
  $enable_aai                = true,
  $subcollections_enabled    = true,
  $dariah_storage_url        = undef,
  $dhpublish_url             = undef,
  $dhcrud_url                = undef,
  $collection_registry_url   = undef,
  $generic_search_url        = undef,
  $pid_service_url           = 'https://hdl.handle.net/',
  $refresh                   = 1750,
  $service_timeout           = 10000,
  $seafile_enabled           = false,
  $seafile_url               = '',
  $seafile_token_secret      = '',
  $ssl_cert_verification     = true,
  $skip_publish_status_check = false,
  $dryrun                    = false,
  $debug                     = false,
  $override_eppn             = false,
  $eppn                      = '',
  $link_to_documentation     = 'https://wiki.de.dariah.eu/display/publicde/Das+DARIAH-DE+Repository',
  $link_to_bugtracker        = 'https://projects.gwdg.de/projects/dariah-de-repository/issues?query_id=151',
  $name_of_contact           = undef,
  $mail_of_contact           = undef,
  $redis_hostname            = 'localhost',
  $redis_port                = 6379,
  $redis_max_parallel        = 40,
  $logout_aai                = "${::fqdn}/Shibboleth.sso/Logout",
) inherits dhrep::params {

  include dhrep::services::tomcat_publikator

  $_name     = $::dhrep::params::publikator_name[$scope]
  $_version  = $::dhrep::params::publikator_version[$scope]
  $_confdir  = $::dhrep::params::confdir
  $_logdir   = $::dhrep::params::logdir
  $_optdir   = $::dhrep::params::optdir
  $_catname  = $::dhrep::params::config['tomcat_publikator']['catname']
  $_aptdir   = $::dhrep::params::aptdir

  $templates = "dhrep/etc/dhrep/publikator/${scope}"

  ###
  # update apt repo and install package
  ###
  package { $_name:
    ensure  => $_version,
    require => [Exec['update_dariah_apt_repository'], Usertomcat::Instance[$_catname]],
  }

  ###
  # symlink war from deb package to tomcat webapps dir
  ###
  file { "/home/${_catname}/${_catname}/webapps/publikator":
    ensure  => 'link',
    target  => "${_aptdir}/publikator",
    require => Usertomcat::Instance[$_catname],
  }

  ###
  # override jndi vars from context.xml
  ###
  file { "/home/${_catname}/${_catname}/conf/context.xml":
    ensure  => file,
    owner   => $_catname,
    group   => $_catname,
    mode    => '0640',
    content => template("${templates}/context.xml.erb"),
    require => Usertomcat::Instance[$_catname],
    notify  => Service[$_catname],
  }

  ###
  # config
  ###
  # create confdir for publikator
  file { "${_confdir}/publikator":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  ###
  # apache config, apache should be there (e.g. by dhrep::init.pp or dariah
  # profile::apache)
  ###
  file { "/etc/apache2/${scope}/default_vhost_includes/publikator.conf":
    content => template("${templates}/publikator.conf.erb"),
    notify  => Service['apache2'],
  }

  ###
  # logging
  ###
#  file { "${_confdir}/${_short}/crud.log4j":
#    ensure  => file,
#    owner   => $_user,
#    group   => $_group,
#    mode    => '0640',
#    content => template("${templates}/crud.log4j.erb"),
#    require => File["${_confdir}/${_short}"],
#  }
#  file { "${_logdir}/${_short}":
#    ensure  => directory,
#    owner   => $_user,
#    group   => $_group,
#    mode    => '0755',
#    require => File[$_logdir],
#  }
#  logrotate::rule { $_short:
#    path         => "${_logdir}/${_short}/crud.log",
#    require      => File["${_logdir}/${_short}"],
#    rotate       => 30,
#    rotate_every => 'day',
#    compress     => true,
#    copytruncate => true,
#    missingok    => true,
#    ifempty      => true,
#    dateext      => true,
#    dateformat   => '.%Y-%m-%d',
#  }
}
