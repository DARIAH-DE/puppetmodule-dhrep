# == Class: textgrid::resources::apache
#
# install and configure apache for textgrid
#
# mainly used by tgauth with mod php and tgnoid with mod-cgi
#
class textgrid::resources::apache {

  class { '::apache':
    default_confd_files => true,
    mpm_module          => prefork,
    default_vhost       => false,
  }

  apache::listen { '8080': }
    
  include apache::mod::php
  include apache::mod::rewrite

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

    # --------------------------------------------------------------------------
    # All the NOID configuration things following here for minting TextGrid URIs
    # --------------------------------------------------------------------------
   
    # ScriptAlias /cgi-bin/ /home/tgnoid/htdocs/nd/
    <Directory \"/home/tgnoid/htdocs/nd/\">
      AuthType Basic
      AuthName \"The TextGrid URI NOID Service\"
      AuthUserFile /etc/apache2/tgnoid.htpasswd
      Require valid-user
      AllowOverride None
      Options +ExecCGI -Includes
      Order allow,deny
      Allow from all
    </Directory>

    # Make the server recognize links to htdocs/nd
    ScriptAliasMatch ^/nd/noidr(.*) \"/home/tgnoid/htdocs/nd/noidr\$1\"
    ScriptAliasMatch ^/nd/noidu(.*) \"/home/tgnoid/htdocs/nd/noidu\$1\"

    # Define all the rewrite maps, start every program once on server start
    # RewriteMap rslv_textgrid prg:/home/tgnoid/htdocs/nd/noidr_textgrid
    
    # --------------------------------------------------------------------------
    # End of NOID configuration
    # --------------------------------------------------------------------------

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
