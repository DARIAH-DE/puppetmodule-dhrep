# == Class: textgrid::services::tgsearch
#
# Class to install and configure tgsearch.
# 
class textgrid::services::intern::tgnoid(
  $tgcrud_secret,
){

  package {
    'libberkeleydb-perl':                ensure => present;
  }

  # require textgrid::resources::apache

  
  # http://search.cpan.org/CPAN/authors/id/J/JA/JAK/Noid-0.424.tar.gz
    

}
