#!/bin/bash

/etc/init.d/postgresql start

# Decide if we need to create the database, or if we have an existing instance.
[ "$(ls -A /malwaredb/database)" ] && echo "Using existing Postgres directory" || ./initialize.sh

/usr/bin/mdb_server run config -p 8080 --ip "0.0.0.0" --dir /malwaredb/samples --db "postgres user=malwaredb password=malwaredb dbname=malwaredb host=localhost" -m "1 GB"
