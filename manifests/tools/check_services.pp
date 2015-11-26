# == Class: dhrep::tools::check_services
#
# checks services within vm
#
class dhrep::tools::check_services (
){

  file { '/opt/dhrep/check-services.sh' :
    source  => 'puppet:///modules/dhrep/opt/dhrep/check-services.sh',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/opt/dhrep'],
  }

}
