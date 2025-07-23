#!/usr/bin/env bash

./1_create_activities_db_parallel.sh
./2_add_foreign_key.sh
./3_explain_select_query.sh
./4_analyze_table.sh
./5_explain_select_query.sh
./6_drop_db.sh
