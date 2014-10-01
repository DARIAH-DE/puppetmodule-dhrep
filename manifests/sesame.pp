class textgrid::sesame {

    $tgname = 'tomcat-sesame'
    $http_port = '9091'
    $control_port = '9006'

    group { $tgname:
        ensure  =>  present,
        gid     =>  '1008',
    }

    user { $tgname:
        ensure      => present,
        uid         => '1008',
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

    tomcat::war { 'openrdf-workbench.war':
        war_ensure      => present,
        catalina_base   => "/home/${tgname}/${tgname}",
        war_source      => 'http://central.maven.org/maven2/org/openrdf/sesame/sesame-http-workbench/2.7.13/sesame-http-workbench-2.7.13.war',
    }

    tomcat::war { 'openrdf-sesame.war':
        war_ensure      => present,
        catalina_base   => "/home/${tgname}/${tgname}",
        war_source      => 'http://central.maven.org/maven2/org/openrdf/sesame/sesame-http-server/2.7.13/sesame-http-server-2.7.13.war',
    }

}
