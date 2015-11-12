#!/bin/bash

# Backup old backup, only if existing :-)
if [ -a /var/textgrid/backups/ldap/ldap-backup.ldif ]; then
	mv /var/textgrid/backups/ldap/ldap-backup.ldif /var/textgrid/backups/ldap/ldap-backup_old.ldif
fi

# Create current backup
sudo slapcat -l /var/textgrid/backups/ldap/ldap-backup.ldif &&

# Remove old logs
sudo db5.1_archive -h /var/lib/ldap -d
