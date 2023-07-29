## Dockerfile for MalwareDB

The image is about ~4GB, could probably be smaller.

```
$ git clone https://github.com/malwaredb/docker.git
$ cd docker
$ docker build -t malwaredb/latest .
$ mkdir mdb_data
$ mkdir mdb_data/db
$ mkdir mdb_data/samples
$ docker run -v `pwd`/mdb_data/db:/var/lib/postgresql/data -v `pwd`/samples:/malware_samples -p 8080:8080 malwaredb/latest
```
