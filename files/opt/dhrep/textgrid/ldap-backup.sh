#!/bin/bash

# Backup old backup, only if existing :-)
if [ -a /var/dhrep/backups/ldap/ldap-backup.ldif.gz ]; then
  sudo mv /var/dhrep/backups/ldap/ldap-backup.ldif.gz /var/dhrep/backups/ldap/ldap-backup_old.ldif.gz
fi

# Create current backup
sudo slapcat -l /var/dhrep/backups/ldap/ldap-backup.ldif
sudo gzip /var/dhrep/backups/ldap/ldap-backup.ldif
