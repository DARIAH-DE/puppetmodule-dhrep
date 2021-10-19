#
# Hash a plaintext using SHA-1 Digest
#
# Example:
#
# sha1digest("hello") # => "{SHA}6d3L1UCJtULYvBnp47aqAvjtfM8="
#
# copied from https://github.com/datacentred/datacentred-ldap/blob/master/lib/puppet/parser/functions/sha1digest.rb
# TODO: SALT {SSHA}
# rewritten to puppet 4 function (https://puppet.com/docs/puppet/7/functions_refactor_legacy.html)
#
Puppet::Functions.create_function(:'dhrep::sha1digest') do
  dispatch :sha1digest do
    param 'String', :input_string
  end

  def sha1digest(input_string)
    "{SHA}#{[Digest::SHA1.digest(input_string)].pack('m0').strip}"
  end
end
