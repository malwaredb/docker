#!/bin/bash

/etc/init.d/postgresql start

sudo -u postgres psql --command "CREATE USER malwaredb WITH PASSWORD 'malwaredb';"
sudo -u postgres psql --command "CREATE DATABASE malwaredb OWNER malwaredb;"
# Add extensions
sudo -u postgres psql -d malwaredb --command "CREATE OR REPLACE FUNCTION fuzzy_hash_compare(TEXT, TEXT) RETURNS INTEGER AS 'ssdeep_psql.so', 'pg_fuzzy_hash_compare' LANGUAGE 'c';"
sudo -u postgres psql -d malwaredb --command "CREATE OR REPLACE FUNCTION tlsh_compare(TEXT, TEXT) RETURNS INTEGER AS 'tlsh_psql.so', 'pg_tlsh_compare' LANGUAGE 'c';"
sudo -u postgres psql -d malwaredb --command "CREATE OR REPLACE FUNCTION sdhash_compare(TEXT, TEXT) RETURNS INTEGER AS 'sdhash_psql.so', 'pg_sdhash_compare' LANGUAGE 'c';"
sudo -u postgres psql -d malwaredb --command "CREATE OR REPLACE FUNCTION lzjd_compare(TEXT, TEXT) RETURNS INTEGER AS 'lzjd_psql.so', 'pg_lzjd_compare' LANGUAGE 'c';"

/usr/bin/mdb_server run config -p 8080 --ip "0.0.0.0" --dir /malware_samples --db "postgres user=malwaredb password=malwaredb dbname=malwaredb host=localhost" -m "1 GB"
