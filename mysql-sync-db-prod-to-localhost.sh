#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./sync_db.sh my_database
#   # OR with overrides:
#   PROD_HOST=prod.mycompany.com TEST_HOST=test.mycompany.com ./sync_db.sh my_database

# ---------- Default values (used if env not set) ----------
DEFAULT_PROD_HOST="prod.db.local"
DEFAULT_PROD_PORT="3306"
DEFAULT_PROD_USER="prod_user"
DEFAULT_PROD_PASS="prod_pass"

DEFAULT_TEST_HOST="127.0.0.1"
DEFAULT_TEST_PORT="3306"
DEFAULT_TEST_USER="root"
DEFAULT_TEST_PASS="root"

# ---------- Pick from ENV or fallback ----------
PROD_HOST="${PROD_HOST:-$DEFAULT_PROD_HOST}"
PROD_PORT="${PROD_PORT:-$DEFAULT_PROD_PORT}"
PROD_USER="${PROD_USER:-$DEFAULT_PROD_USER}"
PROD_PASS="${PROD_PASS:-$DEFAULT_PROD_PASS}"

TEST_HOST="${TEST_HOST:-$DEFAULT_TEST_HOST}"
TEST_PORT="${TEST_PORT:-$DEFAULT_TEST_PORT}"
TEST_USER="${TEST_USER:-$DEFAULT_TEST_USER}"
TEST_PASS="${TEST_PASS:-$DEFAULT_TEST_PASS}"

# ---------- Args ----------
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <DB_NAME>"
  exit 1
fi
DB_NAME="$1"

# ---------- Helpers ----------
mysql_cmd() {
  local host="$1" port="$2" user="$3" pass="$4"
  shift 4
  MYSQL_PWD="${pass}" mysql -h "${host}" -P "${port}" -u "${user}" --protocol=TCP "$@"
}

mysqldump_cmd() {
  local host="$1" port="$2" user="$3" pass="$4"
  shift 4
  MYSQL_PWD="${pass}" mysqldump -h "${host}" -P "${port}" -u "${user}" --protocol=TCP "$@"
}

timestamp() { date +"%Y_%m_%d-%H_%M"; }

# ---------- Dump from PROD ----------
DUMP_FILE="${DB_NAME}.sql"
BACKUP_NAME="${DB_NAME}-$(timestamp)-OLD_SMAZAT"

echo "==> Exporting from PROD: ${PROD_HOST}/${DB_NAME} -> ${DUMP_FILE}"
mysqldump_cmd "${PROD_HOST}" "${PROD_PORT}" "${PROD_USER}" "${PROD_PASS}" \
  --single-transaction --quick --routines --triggers --events \
  --set-gtid-purged=OFF --databases "${DB_NAME}" > "${DUMP_FILE}"

# ---------- Handle TEST/DEV ----------
echo "==> Checking TEST/DEV for existing DB: ${TEST_HOST}/${DB_NAME}"
DB_EXISTS=$(
  mysql_cmd "${TEST_HOST}" "${TEST_PORT}" "${TEST_USER}" "${TEST_PASS}" -Nse \
    "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='${DB_NAME}'" || true
)

if [[ "${DB_EXISTS}" == "${DB_NAME}" ]]; then
  echo "==> DB exists on TEST/DEV. Renaming (cloning) to: ${BACKUP_NAME}"

  mysql_cmd "${TEST_HOST}" "${TEST_PORT}" "${TEST_USER}" "${TEST_PASS}" -e \
    "CREATE DATABASE \`${BACKUP_NAME}\`"

  mysqldump_cmd "${TEST_HOST}" "${TEST_PORT}" "${TEST_USER}" "${TEST_PASS}" \
    --single-transaction --quick --routines --triggers --events \
    --set-gtid-purged=OFF --databases "${DB_NAME}" \
  | sed -E "s/CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`/CREATE DATABASE IF NOT EXISTS \`${BACKUP_NAME}\`/g; s/USE \`${DB_NAME}\`/USE \`${BACKUP_NAME}\`/g" \
  | mysql_cmd "${TEST_HOST}" "${TEST_PORT}" "${TEST_USER}" "${TEST_PASS}"

  mysql_cmd "${TEST_HOST}" "${TEST_PORT}" "${TEST_USER}" "${TEST_PASS}" -e \
    "DROP DATABASE \`${DB_NAME}\`"

  echo "==> Renamed ${DB_NAME} -> ${BACKUP_NAME} on TEST/DEV."
else
  echo "==> DB does not exist on TEST/DEV. Nothing to rename."
fi

# ---------- Import new dump ----------
echo "==> Importing fresh dump into TEST/DEV: ${TEST_HOST}/${DB_NAME}"
mysql_cmd "${TEST_HOST}" "${TEST_PORT}" "${TEST_USER}" "${TEST_PASS}" < "${DUMP_FILE}"

echo "==> Done."
echo "    - Dump file: ${DUMP_FILE}"
if [[ "${DB_EXISTS}" == "${DB_NAME}" ]]; then
  echo "    - Previous TEST/DEV DB saved as: ${BACKUP_NAME}"
fi


# ---------- Ask about dump cleanup ----------
read -r -p "Do you want to keep the SQL dump file ${DUMP_FILE}? (y/n): " KEEP_DUMP
if [[ "${KEEP_DUMP}" =~ ^[Nn]$ ]]; then
  rm -f "${DUMP_FILE}"
  echo "==> Deleted dump file."
else
  echo "==> Keeping dump file."
fi