define textgrid::resources::servicetomcat (
	$gid = undef,
	$uid = undef,
    $http_port = undef,
    $control_port = undef,
){

    group { $name:
        ensure  =>  present,
        gid     =>  $gid,
    }

    user { $name:
        ensure      => present,
        uid         => $uid,
        gid         => $gid,
        shell       => '/bin/bash',
        home        => "/home/${name}",
        managehome  => true,
    }

    exec { "create_${name}":
        path    => ['/usr/bin','/bin','/usr/sbin'],
        command => "tomcat7-instance-create -p ${http_port} -c ${control_port} /home/${name}/${name}",
        creates => "/home/${name}/${name}",
        user    => $name,
		require => Package["tomcat7-user"],
    }

}
