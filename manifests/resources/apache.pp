# == Class: textgrid::resources::apache
#
# install and configure apache for textgrid
#
# mainly used by tgauth with mod php and tgnoid with mod-cgi
#
class textgrid::resources::apache {

  class { '::apache':
    default_confd_files => false,
    mpm_module          => prefork,
    default_vhost       => false,
  }

  apache::listen { '8080': }
    
  include apache::mod::php

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

<VirtualHost *:8080>
    ServerName ${::fqdn}
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
        Order allow,deny
        allow from all
    </Directory>

    ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
    <Directory \"/usr/lib/cgi-bin\">
        AllowOverride None
        Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
        Order allow,deny
        Allow from all
    </Directory>

      Alias /tgauth /var/www/tgauth/rbacSoap
      <Directory \"/var/www/tgauth/rbacSoap\">
                 Options +FollowSymLinks -Indexes
                 Order Allow,Deny
                 Allow from all
      </Directory>


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
