#!/bin/bash
# Script: check_php_mysql_version.sh

echo "=== Checking PHP version ==="
if command -v php >/dev/null 2>&1; then
    php -v | head -n 1
else
    echo "PHP is not installed."
fi

echo ""
echo "=== Checking MySQL/MariaDB version ==="
if command -v mysql >/dev/null 2>&1; then
    db_version=$(mysql --version)
    echo "$db_version"

    if [[ "$db_version" == *"MariaDB"* ]]; then
        echo "Detected: MariaDB"
    elif [[ "$db_version" == *"MySQL"* ]]; then
        echo "Detected: MySQL"
    else
        echo "Database type could not be determined clearly."
    fi
else
    echo "MySQL/MariaDB is not installed."
fi
