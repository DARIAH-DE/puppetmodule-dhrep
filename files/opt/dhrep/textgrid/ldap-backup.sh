#!/bin/bash

# Backup old backup, only if existing :-)
if [ -a /var/dhrep/backups/ldap/ldap-backup.ldif ]; then
  sudo mv /var/dhrep/backups/ldap/ldap-backup.ldif /var/dhrep/backups/ldap/ldap-backup_old.ldif
fi

# Create current backup
sudo slapcat -l /var/dhrep/backups/ldap/ldap-backup.ldif
