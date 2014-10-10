#!/bin/bash

timestamp=$(date +%s)

/etc/init.d/slapd stop
mv /etc/ldap/slapd.d /etc/ldap/slapd.d.bak.$timestamp
mkdir /etc/ldap/slapd.d
#slapadd -l /tmp/ldap-cn-config.ldif
# -n 0 ?
slapadd -F /etc/ldap/slapd.d -l /tmp/ldap-cn-config.ldif -n 0
chown -R openldap:openldap /etc/ldap/slapd.d
/etc/init.d/slapd start

