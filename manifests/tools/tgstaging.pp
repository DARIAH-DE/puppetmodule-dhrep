# == Class: dhrep::tools::tgstaging
#
# Class to cache and unpack and download things.
#
define dhrep::tools::tgstaging(
  $source,
  $target,
  $creates = undef,
){

  $tgcache = '/var/cache/dhrep/'

  staging::file { $name:
    source => $source,
    target => "${tgcache}/${name}",
  }
  -> staging::extract { $name:
    source  => "${tgcache}/${name}",
    target  => $target,
    creates => $creates,
  }
}
