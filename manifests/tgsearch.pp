class textgrid::tgsearch {

    $tgname = 'tomcat-tgsearch'
    $http_port = '9090'
    $control_port = '9005'

    group { $tgname:
        ensure  =>  present,
        gid     =>  '1007',
    }

    user { $tgname:
        ensure      => present,
        uid         => '1007',
        gid         => $tgname,
        shell       => '/bin/bash',
        home        => "/home/${tgname}",
        managehome  => true,
    }

    exec { "create_${tgname}":
        path    => ['/usr/bin','/bin','/usr/sbin'],
        command => "tomcat7-instance-create -p ${http_port} -c ${control_port} /home/${tgname}/${tgname}",
        creates => "/home/${tgname}/${tgname}",
        user    => $tgname,
    }

    tomcat::war { 'tgsearch-service-webapp.war':
        war_ensure      => absent,
        catalina_base   => "/home/${tgname}/${tgname}",
        war_source      => 'http://dev.dariah.eu/nexus/service/local/artifact/maven/redirect?r=releases&g=info.textgrid.middleware&a=tgsearch-service-webapp&v=3.3.0-SNAPSHOT&e=war',
    }

}
