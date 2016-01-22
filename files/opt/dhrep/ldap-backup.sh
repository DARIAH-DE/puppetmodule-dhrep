#!/bin/bash

# Backup old backup, only if existing :-)
if [ -a /var/textgrid/backups/ldap/ldap-backup.ldif ]; then
	sudo mv /var/textgrid/backups/ldap/ldap-backup.ldif /var/textgrid/backups/ldap/ldap-backup_old.ldif
fi

# Create current backup
sudo slapcat -l /var/textgrid/backups/ldap/ldap-backup.ldif

