# == Class: dhrep::services::intern::javagat
#
# Class to install and configure JavaGAT.
#
class dhrep::services::intern::javagat (
  $scope           = undef,
  $javagat_version = '2.1.1',
){

  ###
  # javagat
  ###
  dhrep::tools::tgstaging { "JavaGAT-${javagat_version}-binary.zip":
    source  => "http://gforge.cs.vu.nl/gf/download/frsrelease/154/1196/JavaGAT-${javagat_version}-binary.zip",
    target  => '/usr/local',
    creates => "/usr/local/JavaGAT-${javagat_version}",
  }

  file { '/usr/local/javagat':
    ensure => link,
    target => "/usr/local/JavaGAT-${javagat_version}",
  }
}
