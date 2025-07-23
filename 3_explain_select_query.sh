#!/bin/bash

source "$(dirname "$0")/config.sh"

echo "Running EXPLAIN ANALYZE query on $TABLE_NAME table..."
echo ""

psql -U $DB_USER -d $DB_NAME <<EOF
\timing on

EXPLAIN ANALYZE
SELECT * FROM $TABLE_NAME
WHERE parent_id IN (1, 2);

\timing off
EOF

echo ""
echo "Query analysis complete!"
