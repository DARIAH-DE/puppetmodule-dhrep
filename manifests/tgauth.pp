class textgrid::tgauth (
    $ldap_host = '',
    $binddn_pass = '',
){

    package {
        'slapd':                ensure => present;
        'ldap-utils':           ensure => present;
        'php5-ldap':            ensure => present;
    }

    include textgrid::resources::apache

# anonymous git is broken at gwdg right now

    exec { 'git_clone_tgauth':
        path    => ['/usr/bin','/bin','/usr/sbin'],
#        command => 'git clone git:/git.projects.gwdg.de/tg-auth.git /usr/local/src/tgauth-git',
        command => 'git clone git@git.projects.gwdg.de:tg-auth.git /usr/local/src/tgauth-git',
        creates => '/usr/local/src/tgauth-git',
    }

    file { '/var/www/tgauth':
        source  => 'file:///usr/local/src/tgauth-git/info.textgrid.middleware.tgauth.rbac',
        recurse => true,
    }

    file { '/etc/textgrid/tgauth':
        ensure  => directory,
        owner   => root,
        group   => root,
        mode    => '0755',
        require => File['/etc/textgrid'],
    }

    file { '/etc/textgrid/tgauth/conf':
        ensure  => directory,
        owner   => root,
        group   => root,
        mode    => '0755',
        require => File['/etc/textgrid/tgauth'],
    }

    file { '/etc/textgrid/tgauth/conf/rbac.conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0755',
        content => template('textgrid/etc/textgrid/tgauth/rbac.conf.erb'),
    }

}
