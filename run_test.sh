#!/bin/bash

# --- CONFIGURATION ---
USER_NAME=$(whoami)
INSTALL_DIR="$HOME/postgres-build"
SOURCE_DIR=$(pwd)

# Paths
BIN_DIR="$INSTALL_DIR/bin"
LIB_DIR="$INSTALL_DIR/lib"
DATA_LOCAL="$INSTALL_DIR/data_local"
DATA_FOREIGN="$INSTALL_DIR/data_foreign"
LOG_LOCAL="$INSTALL_DIR/local.log"
LOG_FOREIGN="$INSTALL_DIR/foreign.log"
TAKES_SQL="$SOURCE_DIR/setup_scripts/takes.sql"
COURSE_SQL="$SOURCE_DIR/setup_scripts/course.sql"

# Export environment
export PATH="$BIN_DIR:$PATH"
export LD_LIBRARY_PATH="$LIB_DIR:$LD_LIBRARY_PATH"

# --- CLEANUP FUNCTION ---
cleanup() {
    echo ""
    echo "=========================================="
    echo " STOPPING LOGS AND SHUTTING DOWN..."
    echo "=========================================="
    JOBS=$(jobs -p)
    if [ -n "$JOBS" ]; then
        kill $JOBS 2>/dev/null
    fi
    "$BIN_DIR/pg_ctl" -D "$DATA_LOCAL" stop -m immediate > /dev/null 2>&1
    "$BIN_DIR/pg_ctl" -D "$DATA_FOREIGN" stop -m immediate > /dev/null 2>&1
    echo "Done. Bye!"
    exit
}
trap cleanup SIGINT

# --- STEP 1: BUILD ---
echo "=========================================="
echo " [1/6] COMPILING & INSTALLING..."
echo "=========================================="
rm -rf "$INSTALL_DIR"
make -j4 install > build.log 2>&1
if [ $? -ne 0 ]; then echo "❌ Core build failed. See build.log"; exit 1; fi
cd contrib/postgres_fdw || exit
make clean > /dev/null 2>&1
make install >> ../../build.log 2>&1
if [ $? -ne 0 ]; then echo "❌ Extension build failed. See build.log"; exit 1; fi
cd ../..

# --- STEP 2: SETUP DATA DIRECTORIES ---
echo "=========================================="
echo " [2/6] INITIALIZING DATABASES..."
echo "=========================================="
rm -rf "$DATA_LOCAL" "$DATA_FOREIGN"
"$BIN_DIR/initdb" -D "$DATA_FOREIGN" > /dev/null 2>&1
"$BIN_DIR/initdb" -D "$DATA_LOCAL" > /dev/null 2>&1

# --- STEP 3: START SERVERS ---
echo "=========================================="
echo " [3/6] STARTING SERVERS..."
echo "=========================================="
# Servers start with logging enabled, but we aren't watching yet!
"$BIN_DIR/pg_ctl" -D "$DATA_FOREIGN" -l "$LOG_FOREIGN" -o "-p 5433 -c log_statement=all" start
"$BIN_DIR/pg_ctl" -D "$DATA_LOCAL" -l "$LOG_LOCAL" -o "-p 5432 -c log_statement=all" start
sleep 2

# --- STEP 4: LOAD DATA (SILENT PHASE) ---
echo "=========================================="
echo " [4/6] LOADING DATA (Logs hidden)..."
echo "=========================================="
"$BIN_DIR/createdb" -p 5433 foreigndb
"$BIN_DIR/createdb" -p 5432 localdb

# Load massive SQL files (INSERT logs will go to file but won't be shown)
if [ -f "$TAKES_SQL" ]; then
    "$BIN_DIR/psql" -p 5433 -d foreigndb -f "$TAKES_SQL" > /dev/null 2>&1
fi
if [ -f "$COURSE_SQL" ]; then
    "$BIN_DIR/psql" -p 5432 -d localdb -f "$COURSE_SQL" > /dev/null 2>&1
fi

# Setup FDW (Still hidden)
"$BIN_DIR/psql" -p 5432 -d localdb <<EOF > /dev/null 2>&1
CREATE EXTENSION postgres_fdw;
CREATE SERVER foreign_server FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'localhost', port '5433', dbname 'foreigndb');
CREATE USER MAPPING FOR CURRENT_USER SERVER foreign_server OPTIONS (user '$USER_NAME');
IMPORT FOREIGN SCHEMA public LIMIT TO (takes) FROM SERVER foreign_server INTO public;
ANALYZE course;
EOF

# --- STEP 5: START LIVE LOG STREAMING ---
echo "=========================================="
echo " [5/6] ATTACHING LOGS (Cyan=Foreign, Green=Local)..."
echo "=========================================="


# --- STEP 6: RUN TEST QUERIES ---
echo "=========================================="
echo " [6/6] RUNNING TEST QUERIES..."
echo "=========================================="

# Ensure course table has statistics
"$BIN_DIR/psql" -p 5432 -d localdb -c "ANALYZE course;" > /dev/null 2>&1

# Create a small test table
"$BIN_DIR/psql" -p 5432 -d localdb > /dev/null 2>&1 <<EOF
DROP TABLE IF EXISTS course_small;
CREATE TABLE course_small AS SELECT * FROM course WHERE year IN (2001, 2002, 2003);
ANALYZE course_small;
EOF

echo ""
echo "==========================================  "
echo " TEST 1: Small Local Table (course_small)"
echo "=========================================="
echo ""

# Query 1: Small table join
OUTPUT1=$("$BIN_DIR/psql" -p 5432 -d localdb -c "EXPLAIN (ANALYZE, VERBOSE) SELECT COUNT(*) FROM course_small c WHERE EXISTS (SELECT * FROM takes t WHERE t.year = c.year);" 2>&1)

echo "$OUTPUT1"
echo ""
echo "------------------------------------------"

ROWS_FETCHED1=$(echo "$OUTPUT1" | grep "Foreign Scan on public.takes" -A 10 | grep "actual time" | head -n 1 | sed -E 's/.*rows=([0-9]+).*/\1/')



echo ""
echo "=========================================="
echo " TEST 2: Full Local Table (course)"
echo "=========================================="
echo ""

# Query 2: Full table join
OUTPUT2=$("$BIN_DIR/psql" -p 5432 -d localdb -c "EXPLAIN (ANALYZE, VERBOSE) SELECT COUNT(*) FROM course c WHERE EXISTS (SELECT * FROM takes t WHERE t.year = c.year);" 2>&1)

echo "$OUTPUT2"
echo ""
echo "------------------------------------------"

ROWS_FETCHED2=$(echo "$OUTPUT2" | grep "Foreign Scan on public.takes" -A 10 | grep "actual time" | head -n 1 | sed -E 's/.*rows=([0-9]+).*/\1/')

echo ""
echo "=========================================="
echo " TEST 3: Inner Join  SELECT * FROM course c INNER JOIN takes t ON c.year = t.year;"
echo "=========================================="
echo ""

# query 3: inner join
OUTPUT3=$("$BIN_DIR/psql" -p 5432 -d localdb -c "EXPLAIN (ANALYZE, VERBOSE) SELECT * FROM course c INNER JOIN takes t ON c.year = t.year;" 2>&1)


echo "$OUTPUT3"
echo ""
echo "------------------------------------------"

ROWS_FETCHED3=$(echo "$OUTPUT3" | grep "Foreign Scan on public.takes" -A 10 | grep "actual time" | head -n 1 | sed -E 's/.*rows=([0-9]+).*/\1/')

echo "=========================================="
echo " TEST 4: Multi-Column Inner Join"
echo " SELECT * FROM course c INNER JOIN takes t ON c.course_id = t.course_id AND c.year = t.year;"
echo "=========================================="
echo ""

# query 4: multi-column inner join
OUTPUT4=$("$BIN_DIR/psql" -p 5432 -d localdb -c "EXPLAIN (ANALYZE, VERBOSE) SELECT * FROM course c INNER JOIN takes t ON c.course_id = t.course_id AND c.year = t.year;" 2>&1)

echo "$OUTPUT4"
echo ""
echo "------------------------------------------"

echo "=========================================="
echo " Press Ctrl+C to stop everything."
echo "=========================================="

# Sleep briefly to let logs flush to terminal before cleanup
sleep 2

# Cleanup automatically
cleanup