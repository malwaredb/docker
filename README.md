## Dockerfile for MalwareDB

* It runs, but has a database authentication issue upon re-launch.
* The image is about ~4GB, could probably be smaller.
* The directory which is mapped to `/malwaredb` must be empty for the database to be initialized upon start.

```
$ git clone https://github.com/malwaredb/docker.git
$ cd docker
$ docker build -t malwaredb/latest .
$ mkdir mdb_data
$ docker run -v `pwd`/mdb_data:/malwaredb -p 8080:8080 malwaredb/latest # Run in the directory where you wish to keep the MalwareDB data.
```
