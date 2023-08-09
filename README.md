## Dockerfile for MalwareDB

There are two Dockerfiles:
* `MalwareDB/Dockerfile` builds a container with both Postgres with the extensions and MalwareDB.
* `Postgres/Dockerfile` builds Postgres only with the extensions. This is for installations where MalwareDB should be separate from the database, or by those who'd like to use the similarity extensions.

Both use Postgres 15 from Debian 12 Bookworm.

### Postgres Extensions
Postgres is installed, and extensions built with extensions for:
* [LZJD](https://github.com/malwaredb/LZJD)
* [SSDeep](https://github.com/malwaredb/ssdeep_psql)
* [SDHash](https://github.com/malwaredb/sdhash_psql)
* [TLSH](https://github.com/malwaredb/tlsh_pg)

To use the extensions, you have to add them to your database schema as the schema owner, or as the `postgres` user. SQL commands:
* `CREATE OR REPLACE FUNCTION lzjd_compare(TEXT, TEXT) RETURNS INTEGER AS 'lzjd_psql.so', 'pg_lzjd_compare' LANGUAGE 'c';`
* `CREATE OR REPLACE FUNCTION fuzzy_hash_compare(TEXT, TEXT) RETURNS INTEGER AS 'ssdeep_psql.so', 'pg_fuzzy_hash_compare' LANGUAGE 'c';`
* `CREATE OR REPLACE FUNCTION sdhash_compare(TEXT, TEXT) RETURNS INTEGER AS 'sdhash_psql.so', 'pg_sdhash_compare' LANGUAGE 'c';`
* `CREATE OR REPLACE FUNCTION tlsh_compare(TEXT, TEXT) RETURNS INTEGER AS 'tlsh_psql.so', 'pg_tlsh_compare' LANGUAGE 'c';`

```
$ git clone https://github.com/malwaredb/docker.git
$ cd docker/Postgres
$ docker build -t postgres-similarity/latest .
$ mkdir pg_data
$ docker run -v `pwd`/pg_data:/var/lib/postgresql/data -p 5432:5432 postgres-similarity/latest
```

### MalwareDB
The images are about ~4GB, could probably be smaller. The SQL commands for adding the fuzzy hash functions above are added by the `start.sh` script at container start. The Postgres server won't be accessible outside the container.

```
$ git clone https://github.com/malwaredb/docker.git
$ cd docker/MalwareDB
$ docker build -t malwaredb/latest .
$ mkdir mdb_data
$ mkdir mdb_data/db
$ mkdir mdb_data/samples
$ docker run -v `pwd`/mdb_data/db:/var/lib/postgresql/data -v `pwd`/samples:/malware_samples -p 8080:8080 malwaredb/latest
```
