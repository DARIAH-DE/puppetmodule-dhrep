class textgrid::nginx {

    package { 'nginx': ensure  => present; }

	file { '/etc/nginx/proxyconf':
        ensure  => directory,
        owner   => root,
        group   => root,
        mode    => '0755',
        require => Package['nginx'],
    }

	file { '/etc/nginx/proxyconf/1.0.conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0644',
        content => template('textgrid/etc/nginx/proxyconf/1.0.conf.erb'),
    }

}
