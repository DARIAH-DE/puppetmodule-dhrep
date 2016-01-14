#!/bin/bash

timestamp=$(date +%s)

/etc/init.d/slapd stop
mv /etc/ldap/slapd.d /etc/ldap/slapd.d.bak.$timestamp
mv /var/lib/ldap/ /var/lib/ldap.bak.$timestamp
mkdir /etc/ldap/slapd.d
mkdir /var/lib/ldap
#slapadd -l /tmp/ldap-cn-config.ldif
# -n 0 ?
slapadd -F /etc/ldap/slapd.d -l /tmp/ldap-cn-config.ldif -n 0
chown -R openldap:openldap /etc/ldap/slapd.d
chown -R openldap:openldap /var/lib/ldap
/etc/init.d/slapd start

