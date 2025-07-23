#!/bin/bash

source "$(dirname "$0")/config.sh"

echo "Creating database: $DB_NAME"
createdb -U $DB_USER $DB_NAME 2>/dev/null || echo "Database already exists"

echo "Creating table and preparing for parallel insert of $ROWS_TO_INSERT rows..."

# Create table and function
psql -U $DB_USER -d $DB_NAME <<EOF
-- Drop table if exists
DROP TABLE IF EXISTS $TABLE_NAME;

-- Create activities table
CREATE TABLE $TABLE_NAME (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Create function to generate random names
CREATE OR REPLACE FUNCTION generate_random_name() RETURNS VARCHAR AS \$\$
DECLARE
    first_names TEXT[] := ARRAY['John', 'Jane', 'Mike', 'Sarah', 'Tom', 'Lisa', 'David', 'Emma', 'Chris', 'Anna'];
    last_names TEXT[] := ARRAY['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez'];
    activities TEXT[] := ARRAY['Running', 'Swimming', 'Cycling', 'Hiking', 'Reading', 'Coding', 'Gaming', 'Cooking', 'Painting', 'Dancing'];
BEGIN
    RETURN first_names[1 + floor(random() * 10)] || ' ' ||
           last_names[1 + floor(random() * 10)] || ' - ' ||
           activities[1 + floor(random() * 10)];
END;
\$\$ LANGUAGE plpgsql;

-- Drop primary key to speed up bulk inserts
ALTER TABLE $TABLE_NAME DROP CONSTRAINT activities_pkey;
EOF

echo "Starting parallel inserts with $PARALLEL_JOBS jobs..."
START_TIME=$(date +%s)

# Function to insert a range of rows
insert_range() {
    local start_id=$1
    local end_id=$2
    local job_num=$3

    echo "Job $job_num: Inserting rows $start_id to $end_id..."

    psql -U $DB_USER -d $DB_NAME -q <<EOF
INSERT INTO $TABLE_NAME (id, name)
SELECT
    s as id,
    generate_random_name() as name
FROM generate_series($start_id, $end_id) s;
EOF

    echo "Job $job_num: Completed"
}

# Start parallel insert jobs
for ((i=0; i<$PARALLEL_JOBS; i++)); do
    start_id=$((i * ROWS_PER_JOB + 1))
    if [ $i -eq $((PARALLEL_JOBS - 1)) ]; then
        # Last job gets any remainder rows
        end_id=$ROWS_TO_INSERT
    else
        end_id=$(((i + 1) * ROWS_PER_JOB))
    fi

    insert_range $start_id $end_id $((i+1)) &
done

# Wait for all jobs to complete
wait

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "All parallel inserts completed in $DURATION seconds"
echo "Recreating primary key and creating indexes..."

# Recreate primary key and analyze table
psql -U $DB_USER -d $DB_NAME <<EOF
\timing on

-- Recreate primary key
ALTER TABLE $TABLE_NAME ADD CONSTRAINT activities_pkey PRIMARY KEY (id);

-- Analyze table for query optimizer
ANALYZE $TABLE_NAME;

-- Show table statistics
SELECT
    'Total rows inserted: ' || COUNT(*) as result
FROM $TABLE_NAME
UNION ALL
SELECT
    'Table size: ' || pg_size_pretty(pg_total_relation_size('$TABLE_NAME'))
UNION ALL
SELECT
    'Sample names: '
UNION ALL
SELECT
    '  - ' || name
FROM $TABLE_NAME
LIMIT 5;

\timing off
EOF

echo "Database creation and population complete!"
echo "Total time: $DURATION seconds"
