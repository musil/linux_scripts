# Linux scripts


## mysql-export-per-db.sh
Export all databases in a MySQL instance to separate files. And keeps retention of 7 days.

```crontab
0 2 * * * /path/to/mysql-export-per-db.sh
```

backup account requires privileges:

```sql
CREATE USER 'backup'@'localhost' IDENTIFIED BY 'password';
GRANT SHOW DATABASES, SELECT, LOCK TABLES, RELOAD, SHOW VIEW ON *.* TO 'backup'@'localhost';
```

