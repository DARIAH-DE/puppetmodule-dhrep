class textgrid::tgcrud {

    $tgname = 'tomcat-tgcrud'
    $http_port = '9093'
    $control_port = '9008'

    group { 'ULSB':
        ensure  =>  present,
        gid     =>  '29900',
    }

    user { 'textgrid':
        ensure      => present,
        uid         => '49628',
        gid         => ULSB,
        shell       => '/bin/bash',
        home        => "/home/textgrid",
        managehome  => true,
    }

    exec { "create_${tgname}":
        path    => ['/usr/bin','/bin','/usr/sbin'],
        command => "tomcat7-instance-create -p ${http_port} -c ${control_port} /home/textgrid/${tgname}",
        creates => "/home/textgrid/${tgname}",
        user    => 'textgrid',
    }

#    tomcat::war { 'tgsearch-service-webapp.war':
#        war_ensure      => absent,
#        catalina_base   => "/home/textgrid/${tgname}",
#        war_source      => 'http://dev.dariah.eu/nexus/service/local/artifact/maven/redirect?r=releases&g=info.textgrid.middleware&a=tgsearch-service-webapp&v=3.3.0-SNAPSHOT&e=war',
#    }

}
