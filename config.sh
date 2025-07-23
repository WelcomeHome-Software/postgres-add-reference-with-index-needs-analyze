#!/bin/bash

export DB_NAME="activities_db"
export DB_USER="postgres"
export TABLE_NAME="activities"
export ROWS_TO_INSERT=100000000
export PARALLEL_JOBS=8
export ROWS_PER_JOB=$((ROWS_TO_INSERT / PARALLEL_JOBS))
