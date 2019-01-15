# == Class: dhrep::services::publikator
#
# Class to install and configure THE PUBLIKATOR service.
#
class dhrep::services::publikator (
  $scope                     = undef,
  $enable_aai                = true,
  $subcollections_enabled    = true,
  $dariah_storage_url        = 'https://cdstar.de.dariah.eu/dariah/',
  $dhpublish_url             = "https://${::fqdn}/1.0/dhpublish/",
  $dhcrud_url                = "https://${::fqdn}/1.0/dhcrud/",
  $collection_registry_url   = 'https://colreg.de.dariah.eu/colreg-ui/',
  $generic_search_url        = 'https://search.de.dariah.eu/search/',
  $pid_service_url           = 'https://hdl.handle.net/',
  $pdp_token_server_url      = 'https://pdp.de.dariah.eu/oauth2/oauth2/authorize?response_type=token&amp;client_id=dariah-de-publikator&amp;scope=read,write&amp;redirect_uri=',
  $pdp_token_manager_url     = 'https://auth.de.dariah.eu/cgi-bin/selfservice/ldapportal.pl?mode=authenticate&amp;shibboleth=1&amp;nextpage=accesstokenmanagement',
  $refresh                   = 2850,
  $service_timeout           = 10000,
  $seafile_enabled           = false,
  $seafile_url               = undef,
  $seafile_token_secret      = undef,
  $ssl_cert_verification     = true,
  $skip_publish_status_check = false,
  $dryrun                    = false,
  $debug                     = false,
  $override_eppn             = false,
  $eppn                      = 'publikator',
  $link_to_documentation     = "https://${::fqdn}/doc/services/submodules/publikator/docs/index.html",
  $link_to_faq               = 'https://wiki.de.dariah.eu/display/publicde/FAQs+zum+Publikator',
  $link_to_apidoc            = "https://${::fqdn}/doc/services/",
  $link_to_privpol           = 'https://de.dariah.eu/privacy-policy',
  $link_to_bugtracker        = 'https://projects.gwdg.de/projects/dariah-de-repository/work_packages',
  $name_of_contact           = 'DARIAH-DE Support',
  $mail_of_contact           = 'support@de.dariah.eu',
  $redis_hostname            = 'localhost',
  $redis_port                = 6379,
  $redis_max_parallel        = 100,
  $publish_secret            = undef,
  $badge_text                = undef,
  $maxuploadsize             = 4096,
  $logout_aai                = "https://${::fqdn}/Shibboleth.sso/Logout",
  $statsd_enable             = true,
  $statsd_hostname           = localhost,
  $statsd_port               = 8125,
  $skip_landing_page         = false,
  $instance_name             = 'PROD',
) inherits dhrep::params {

  include dhrep::services::tomcat_publikator
  include roles::dariahrepository

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
  # override jndi vars from context.xml
  ###
  file { "/home/${_catname}/${_catname}/conf/context.xml":
    ensure  => file,
    owner   => $_catname,
    group   => $_catname,
    mode    => '0640',
    content => template("${templates}/context.xml.erb"),
    require => File["${_confdir}/publikator"],
    notify  => Service[$_catname],
  }

  ###
  # apache config (for using shibboleth)
  ###
  if ($::roles::dariahrepository::with_shib) {
    file { "/etc/apache2/${scope}/default_vhost_includes/publikator.conf":
      content => template("${templates}/publikator.conf.erb"),
      notify  => Service['apache2'],
    }
  }
  else {
    file { "/etc/apache2/${scope}/default_vhost_includes/publikator.conf":
      ensure => absent,
      notify => Service['apache2'],
    }
  }

  ###
  # logging
  ###
  # TODO why is logging configuration commented out?
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
