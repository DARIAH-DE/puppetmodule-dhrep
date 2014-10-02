class textgrid::tgnginx {

    package { 'nginx': ensure  => present; }

#    class { 'nginx':
#        http_cfg_append => {
#            client_body_buffer_size => '512k',
#            chunkin => 'on',
#        }
#    }

	service { 'nginx':
    	ensure  => running,
    	enable  => true,
    	require => Package["nginx"],
	}

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
		notify  => Service['nginx'],
    }

	file { '/etc/nginx/sites-available/default':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0644',
        content => template('textgrid/etc/nginx/sites-available/default.erb'),
		notify  => Service['nginx'],
    }


}
