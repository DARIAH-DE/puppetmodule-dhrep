# == Class: textgrid::services::intern::sesame
#
# Class to install and configure sesame.
# Creates initial repos textgrid-nonpublic 
# and textgrid-public and adds initial triples.
# 
# TODO:
#   repo init should only run once
#
class textgrid::services::intern::sesame {

  $tgname = 'tomcat-sesame'
  $http_port = '9091'
  $control_port = '9006'
  $jmx_port = '9991'

  $sesame_version = '2.7.13'
  $sesame_file = "openrdf-sesame-${sesame_version}-sdk.tar.gz"

  textgrid::resources::servicetomcat { $tgname:
    gid          => '1008',
    uid          => '1008',
    http_port    => $http_port,
    control_port => $control_port,
    jmx_port     => $jmx_port,
  }

#  staging::deploy { $sesame_file:
#    source => "http://sourceforge.net/projects/sesame/files/Sesame%202/${sesame_version}/${sesame_file}/download",
#    target => "/home/${tgname}",
#    notify => [Tomcat::War['openrdf-workbench.war'], Tomcat::War['openrdf-sesame.war']],
#  }

  tomcat::war { 'openrdf-workbench.war':
    war_ensure    => present,
    catalina_base => "/home/${tgname}/${tgname}",
    war_source    => "http://central.maven.org/maven2/org/openrdf/sesame/sesame-http-workbench/${sesame_version}/sesame-http-workbench-${sesame_version}.war",
    require       => [Textgrid::Resources::Servicetomcat[$tgname]],
  }

  tomcat::war { 'openrdf-sesame.war':
    war_ensure    => present,
    catalina_base => "/home/${tgname}/${tgname}",
    war_source    => "http://central.maven.org/maven2/org/openrdf/sesame/sesame-http-server/${sesame_version}/sesame-http-server-${sesame_version}.war",
    require       => [Textgrid::Resources::Servicetomcat[$tgname],Tomcat::War['openrdf-workbench.war']],
  }

  file { "/home/${tgname}/mime.ttl":
    ensure => present,
    owner  => $tgname,
    group  => $tgname,
    mode   => '0644',
    source => 'puppet:///modules/textgrid/rdf/mime.ttl',
  }

#  unless $sesame_nonpublic_repo_created {
    create_tgrepo{'textgrid-nonpublic':
      port    => '9091',
      user    => $tgname,
      require => [Tomcat::War['openrdf-sesame.war'],Tomcat::War['openrdf-workbench.war']],
    }
#    file {'/etc/facter/facts.d/sesame_nonpublic.txt':
#      content => "sesame_nonpublic_repo_created=true",
#    }
#  }

# need to wait for tomcat before creating repo
# http://stackoverflow.com/questions/8244663/puppet-wait-for-a-service-to-be-ready
#exec {"wait for tomcat":
#  require => Service["tomcat6"],
#  command => "/usr/bin/wget --spider --tries 10 --retry-connrefused --no-check-certificate https://localhost:8443/service/",
#}

#  unless $sesame_public_repo_created {
    create_tgrepo{'textgrid-public':
      port => '9091',
      user => $tgname,
      require => [Tomcat::War['openrdf-sesame.war'],Tomcat::War['openrdf-workbench.war']],
    }
#    file {'/etc/facter/facts.d/sesame_public.txt':
#      content => "sesame_public_repo_created=true",
#    }
#  }

  define create_tgrepo (
    $port = '9091',
    $user = 'tomcat-sesame'
  ) {

    $create_target = shellquote("http://localhost:${port}/openrdf-workbench/repositories/SYSTEM/create")
    $create_data = shellquote("type=native&Repository+ID=${name}&Repository+title=rdf+repo+for+${name}+data&Triple+indexes=spoc%2Cposc%2Copsc%2Csopc")

    exec { "create_repo_${name}":
      path    => ['/usr/bin','/bin','/usr/sbin'],
      command => "curl ${create_target} --data ${create_data}",
    }

    $ttl_target = shellquote("http://localhost:${port}/openrdf-sesame/repositories/${name}/statements")

    exec { "ttl_to_repo_${name}":
      path    => ['/usr/bin','/bin','/usr/sbin'],
      command => "curl ${ttl_target} -X POST -d @/home/tomcat-sesame/mime.ttl --header 'Content-Type: text/turtle;charset=UTF-8'",
      require => [Exec["create_repo_${name}"],File["/home/${user}/mime.ttl"]],
    }

  }


}
