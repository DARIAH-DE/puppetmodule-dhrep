# == Class: dhrep::resources::apache
#
# install and configure apache for textgrid
#
# mainly used by tgauth with mod php and tgnoid with mod-cgi
#
class dhrep::resources::apache (
  $scope = undef,
  $port  = '8080',
){

  file { '/etc/apache2':
    ensure => directory,
  }

  file { "/etc/apache2/${scope}":
    ensure => directory,
  }

  file { "/etc/apache2/${scope}/default_vhost_includes":
    ensure => directory,
  }

  class { '::apache':
    default_confd_files => true,
    mpm_module          => prefork,
    default_vhost       => false,
  }

  apache::listen { $port: }

  include apache::mod::php
  include apache::mod::rewrite
  include apache::mod::cgi

  # TODO: sites-available & a2ensite
  $defaultvhost = "/etc/apache2/sites-enabled/25-${::fqdn}.conf"
  concat { $defaultvhost:
    owner  => root,
    group  => root,
    mode   => '0644',
    notify => Service['apache2'],
  }

  # Shibboleth configuration for Apache
  # (see dariahshibboleth/README.md)
  package { 'libapache2-mod-shib2':
<<<<<<< HEAD
    ensure => absent,
=======
    ensure => present,
    before => Package['shibboleth'],
>>>>>>> master
  }

  ::apache::mod { 'shib2':
    id  => 'mod_shib',
    lib => 'mod_shib2.so',
  }

  concat::fragment{'apache_default_head':
    target  => $defaultvhost,
    content => "
#####################
# MANAGED BY PUPPET #
#####################

<VirtualHost *:${port}>
    ServerName https://${::dhrep::public_hostname}
    ServerAdmin webmaster@localhost
    UseCanonicalName On

    DocumentRoot /var/www

    <Directory />
        Options FollowSymLinks
        AllowOverride None
    </Directory>
    <Directory /var/www/>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride None
        Require all granted
    </Directory>

    ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
    <Directory /usr/lib/cgi-bin>
        AllowOverride None
        Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
        Require all granted
    </Directory>

    IncludeOptional /etc/apache2/${scope}/default_vhost_includes/*.conf

    ErrorLog \${APACHE_LOG_DIR}/error.log

    # Possible values include: debug, info, notice, warn, error, crit,
    # alert, emerg.
    LogLevel warn

    CustomLog \${APACHE_LOG_DIR}/access.log combined
    ",
    order   => 010,
  }

  concat::fragment{'apache_default_tail':
    target  => $defaultvhost,
    content => "
</VirtualHost>
    ",
    order   => 990,
  }
}
