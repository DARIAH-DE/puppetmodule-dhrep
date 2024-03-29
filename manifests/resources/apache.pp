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

  include '::apache::mod::php'
  include '::apache::mod::rewrite'
  include '::apache::mod::cgi'
  include '::apache::mod::proxy'
  include '::apache::mod::proxy_http'
  include '::apache::mod::headers'

  # TODO: sites-available & a2ensite
  $defaultvhost = "/etc/apache2/sites-enabled/25-${::fqdn}.conf"
  concat { $defaultvhost:
    owner  => root,
    group  => root,
    mode   => '0644',
    notify => Service['apache2'],
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

    <Directory />
        Options FollowSymLinks
        AllowOverride None
    </Directory>
  ",
    order   => '010',
  }

  if $scope == 'textgrid' {
    concat::fragment{'apache_textgrid':
      target  => $defaultvhost,
      content => '
    DocumentRoot /var/www

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

    # disable entityID forward to the SP\'s Login Handler, IdP is the proxy
    RewriteEngine On
    RewriteCond      %{QUERY_STRING}    (.*?)&entityID=.*
    RewriteRule      /(.*)               /$1?%1         [R=302,NE,L]
    ',
      order   => '020',
    }
  }

  concat::fragment{'apache_default_tail':
    target  => $defaultvhost,
    content => "
    IncludeOptional /etc/apache2/${scope}/default_vhost_includes/*.conf

    ErrorLog \${APACHE_LOG_DIR}/error.log

    # Possible values include: debug, info, notice, warn, error, crit,
    # alert, emerg.
    LogLevel warn

    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
    ",
    order   => '990',
  }

  ###
  # monitor apache processes with telegraf
  # exe: executable name (ie, pgrep <exe>)
  ###
  telegraf::input { 'apache2_procstat':
    plugin_type => 'procstat',
    options     => [{
      'exe'     => 'apache2',
      'pid_tag' => true,
    }],
  }

}
