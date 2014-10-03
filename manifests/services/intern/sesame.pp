class textgrid::services::intern::sesame {

    $tgname = 'tomcat-sesame'
    $http_port = '9091'
    $control_port = '9006'
	$jmx_port = '9991'

	textgrid::resources::servicetomcat { $tgname:
		gid => '1008',
		uid => '1008',
    	http_port => $http_port,
    	control_port => $control_port,
		jmx_port => $jmx_port,
	}

    tomcat::war { 'openrdf-workbench.war':
        war_ensure      => present,
        catalina_base   => "/home/${tgname}/${tgname}",
        war_source      => 'http://central.maven.org/maven2/org/openrdf/sesame/sesame-http-workbench/2.7.13/sesame-http-workbench-2.7.13.war',
		require			=> Textgrid::Resources::Servicetomcat[$tgname],
    }

    tomcat::war { 'openrdf-sesame.war':
        war_ensure      => present,
        catalina_base   => "/home/${tgname}/${tgname}",
        war_source      => 'http://central.maven.org/maven2/org/openrdf/sesame/sesame-http-server/2.7.13/sesame-http-server-2.7.13.war',
		require			=> Textgrid::Resources::Servicetomcat[$tgname],
    }

	# add tg repos
	

}
