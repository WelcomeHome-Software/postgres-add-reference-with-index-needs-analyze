# PostgreSQL ANALYZE Demo

This demo shows ANALYZE is required for PostgreSQL to use index scans instead of
sequential scans on large tables after adding a new foreign key column with an
index.

## Scripts (run in order)

1. `1_create_activities_db_parallel.sh` - Creates database with 100M rows and indexes
2. `2_add_foreign_key.sh` - Adds parent_id column with foreign key and index
3. `3_explain_select_query.sh` - Shows query plan (likely Seq Scan)
4. `4_analyze_table.sh` - Updates table statistics
5. `5_explain_select_query.sh` - Shows query plan again (now Index Scan)
6. `6_drop_db.sh` - Cleanup

Or, run it all at once with `./run_all.sh`. This is more convenient, but does
not allow introspection of the database between steps.

Script 1 takes 1+ minutes to run, depending on hardware. The subsequent scripts
are much faster.

## Key Point

Without ANALYZE, PostgreSQL's query planner lacks accurate statistics about
table data distribution. This causes it to choose sequential scans even when
indexes exist. After ANALYZE updates the statistics, the planner correctly
chooses the more efficient index scan for selective queries.
