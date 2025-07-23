#!/bin/bash

source "$(dirname "$0")/config.sh"

echo "Analyzing $TABLE_NAME table..."
echo ""

psql -U $DB_USER -d $DB_NAME <<EOF
\timing on

ANALYZE $TABLE_NAME;

-- Show updated statistics
SELECT
    'Table analyzed: ' || relname as result,
    'Last analyzed: ' || last_analyze::timestamp(0) as last_analyzed,
    'Rows: ' || n_live_tup as row_count
FROM pg_stat_user_tables
WHERE relname = '$TABLE_NAME';

\timing off
EOF

echo ""
echo "Table analysis complete!"
