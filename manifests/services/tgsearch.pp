class textgrid::services::tgsearch {

  $tgname = 'tomcat-tgsearch'
  $http_port = '9090'
  $control_port = '9005'
  $jmx_port = '9990'

  textgrid::resources::servicetomcat { $tgname:
    gid          => '1007',
    uid          => '1007',
    http_port    => $http_port,
    control_port => $control_port,
    jmx_port     => $jmx_port,
  }

  tomcat::war { 'tgsearch-service-webapp.war':
    war_ensure    => absent,
    catalina_base => "/home/${tgname}/${tgname}",
    war_source    => 'http://dev.dariah.eu/nexus/service/local/artifact/maven/redirect?r=releases&g=info.textgrid.middleware&a=tgsearch-service-webapp&v=3.3.0-SNAPSHOT&e=war',
    require       => Textgrid::Resources::Servicetomcat[$tgname],
  }

}
