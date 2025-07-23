#!/bin/bash

source "$(dirname "$0")/config.sh"

echo "Dropping database: $DB_NAME"
echo "WARNING: This will permanently delete all data in the database!"
echo ""

# Terminate existing connections to the database
psql -U $DB_USER -d postgres <<EOF
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '$DB_NAME'
  AND pid <> pg_backend_pid();
EOF

# Drop the database
dropdb -U $DB_USER $DB_NAME

if [ $? -eq 0 ]; then
    echo "Database $DB_NAME dropped successfully."
else
    echo "Failed to drop database $DB_NAME (it may not exist)."
fi
