#!/bin/bash
TIMESTAMP=$(date +"%F")
BACKUP_DIR="/backup/mysql/$TIMESTAMP"
MYSQL_USER="backup"
MYSQL=/usr/bin/mysql
MYSQL_PASSWORD="__PASSWORD__"
MYSQLDUMP=/usr/bin/mysqldump
 
mkdir -p "$BACKUP_DIR"
 
databases=`$MYSQL --user=$MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)"`
 
for db in $databases; do
  $MYSQLDUMP --force --opt --user=$MYSQL_USER -p$MYSQL_PASSWORD --databases $db | gzip > "$BACKUP_DIR/$db-$TIMESTAMP.gz"
done

find /backup/mysql -type d -mtime +7 -exec rm -rf {} \;
