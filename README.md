## Dockerfile for Postgres for MalwareDB

This Docker file builds extensions for Postgres on Debian for use with MalwareDB.

### Postgres Extensions
Postgres is installed, and extensions built with extensions for:
* [LZJD](https://github.com/malwaredb/LZJD)
* [SSDeep](https://github.com/malwaredb/ssdeep_psql)
* [TLSH](https://github.com/malwaredb/tlsh_pg)

To use the extensions, __you__ have to add them to __each__ database schema you wish to use them as the schema owner, or as the `postgres` user. SQL commands:
* `CREATE OR REPLACE FUNCTION lzjd_compare(TEXT, TEXT) RETURNS INTEGER AS 'lzjd_psql.so', 'pg_lzjd_compare' LANGUAGE 'c';`
* `CREATE OR REPLACE FUNCTION fuzzy_hash_compare(TEXT, TEXT) RETURNS INTEGER AS 'ssdeep_psql.so', 'pg_fuzzy_hash_compare' LANGUAGE 'c';`
* `CREATE OR REPLACE FUNCTION tlsh_compare(TEXT, TEXT) RETURNS INTEGER AS 'tlsh_psql.so', 'pg_tlsh_compare' LANGUAGE 'c';`

Be sure to set the admin password for Postgres via the `POSTGRES_PASSWORD` environment variable, shown below.

```
$ git clone https://github.com/malwaredb/docker.git
$ docker build -t postgres-similarity/latest .
$ mkdir pg_data
$ docker run -v `pwd`/pg_data:/var/lib/postgresql/data -p 5432:5432 -e POSTGRES_PASSWORD=yoursecurepassword postgres-similarity/latest
```
