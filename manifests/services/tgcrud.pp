class textgrid::services::tgcrud (
	$aai_special_secret = '',
	$id_service_pass = '',
	$publish_secret = '',
){

    $tgname = 'tomcat-tgcrud'
    $http_port = '9093'
    $control_port = '9008'

	# TODO modify textgrid::resources::servicetomcat to choose group and username, then use here
    group { 'ULSB':
        ensure  =>  present,
        gid     =>  '29900',
    }

    user { 'textgrid':
        ensure      => present,
        uid         => '49628',
        gid         => 'ULSB',
        shell       => '/bin/bash',
        home        => "/home/textgrid",
        managehome  => true,
    }

    exec { "create_${tgname}":
        path    => ['/usr/bin','/bin','/usr/sbin'],
        command => "tomcat7-instance-create -p ${http_port} -c ${control_port} /home/textgrid/${tgname}",
        creates => "/home/textgrid/${tgname}",
        user    => 'textgrid',
		require => Package["tomcat7-user"],
    }

    tomcat::war { 'tgcrud.war':
        war_ensure      => present,
        catalina_base   => "/home/textgrid/${tgname}",
        war_source      => 'http://dev.dariah.eu/nexus/content/repositories/releases/info/textgrid/middleware/tgcrud-base/5.0.1/tgcrud-base-5.0.1.war',
		require			=> Exec["create_${tgname}"],
    }

	file { '/etc/textgrid/tgcrud':
        ensure  => directory,
        owner   => root,
        group   => root,
        mode    => '0755',
        require => File['/etc/textgrid'],
    }

    file { '/etc/textgrid/tgcrud/tgcrud.properties':
        ensure  => present,
        owner   => 'textgrid',
        group   => 'ULSB',
        mode    => '0600',
        content => template('textgrid/etc/textgrid/tgcrud/tgcrud.properties.erb'),
    }

    file { '/etc/textgrid/tgcrud/tgcrud.log4j':
        ensure  => present,
        owner   => 'textgrid',
        group   => 'ULSB',
        mode    => '0600',
        content => template('textgrid/etc/textgrid/tgcrud/tgcrud.log4j.erb'),
    }

	file { '/var/log/textgrid/tgcrud':
        ensure  => directory,
        owner   => 'textgrid',
        group   => 'ULSB',
        mode    => '0755',
        require => File['/var/log/textgrid'],
    }

    file { '/data':
        ensure  => directory,
        owner   => 'textgrid',
        group   => 'ULSB',
        mode    => '0755',
    }

	# TODO: decide wether to mount stornext or create local data dir

    #mount { '/media/stornext':
    #  device  => 'fs-base3.gwdg.de:/home/textgrid/',
    #  fstype  => 'nfs',
    #  ensure  => 'mounted',
    #  options => 'defaults',
    #  atboot  => true,
    #  require => [File['/mnt/storage'],Package['nfs-common']],
    #}

    file { '/data/public':
        ensure  => directory,
        owner   => 'textgrid',
        group   => 'ULSB',
        mode    => '0755',
		require => File['/data'],
    }

    file { '/data/nonpublic':
        ensure  => directory,
        owner   => 'textgrid',
        group   => 'ULSB',
        mode    => '0755',
		require => File['/data'],
    }
}
