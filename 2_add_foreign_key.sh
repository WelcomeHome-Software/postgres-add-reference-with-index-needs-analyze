#!/bin/bash

source "$(dirname "$0")/config.sh"

echo "Adding self-referential foreign key to $TABLE_NAME table..."

psql -U $DB_USER -d $DB_NAME <<EOF
\timing on

-- Add parent_id column
ALTER TABLE $TABLE_NAME ADD COLUMN parent_id INTEGER;

-- Create index on parent_id for better performance
CREATE INDEX CONCURRENTLY idx_activities_parent_id ON $TABLE_NAME(parent_id);

-- Add foreign key constraint
ALTER TABLE $TABLE_NAME
ADD CONSTRAINT fk_activities_parent
FOREIGN KEY (parent_id)
REFERENCES $TABLE_NAME(id)
NOT VALID;

-- Validate foreign key constraint
ALTER TABLE $TABLE_NAME VALIDATE CONSTRAINT "fk_activities_parent";

\timing off
EOF

echo "Foreign key and index added successfully!"
