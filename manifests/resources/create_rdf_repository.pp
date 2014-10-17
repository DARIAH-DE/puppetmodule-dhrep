# == Define: textgrid::resources::create_rdf_repository
#
# Creates a sesame repository adds initial triples.
#

define textgrid::resources::create_rdf_repository (
  $port = '9091',
  $user = 'tomcat-sesame'
) {

  $create_target = shellquote("http://localhost:${port}/openrdf-workbench/repositories/SYSTEM/create")
  $create_data = shellquote("type=native&Repository+ID=${name}&Repository+title=rdf+repo+for+${name}+data&Triple+indexes=spoc%2Cposc%2Copsc%2Csopc")
  $ttl_target = shellquote("http://localhost:${port}/openrdf-sesame/repositories/${name}/statements")

  # need to wait for tomcat before creating repo  
  # http://stackoverflow.com/questions/8244663/puppet-wait-for-a-service-to-be-ready
  exec {"wait_for_sesame_${name}":
    path    => ['/usr/bin','/bin','/usr/sbin'],
    command => "/usr/bin/wget --spider --tries 10 --retry-connrefused http://localhost:${port}/openrdf-sesame/repositories",
  }
  ~>
  exec {"wait_for_workbench_${name}":
    path    => ['/usr/bin','/bin','/usr/sbin'],
    command => "/usr/bin/wget --spider --tries 10 --retry-connrefused http://localhost:${port}/openrdf-workbench/",
  }
  ~>
  exec { "create_repo_${name}":
    path    => ['/usr/bin','/bin','/usr/sbin'],
    command => "curl ${create_target} --data ${create_data}",
  }
  ~>
  exec { "ttl_to_repo_${name}":
    path    => ['/usr/bin','/bin','/usr/sbin'],
    command => "curl ${ttl_target} -X POST -d @/home/${user}/mime.ttl --header 'Content-Type: text/turtle;charset=UTF-8'",
    require => [Exec["create_repo_${name}"],File["/home/${user}/mime.ttl"],],
  }

}

