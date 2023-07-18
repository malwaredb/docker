## Dockerfile for MalwareDB

Currently untested.

```
$ git clone https://github.com/malwaredb/docker.git
$ cd docker
$ docker build -t malwaredb/latest .
$ docker run -v `pwd`:/malwaredb --expose=8080 malwaredb/latest # Run in the directory where you wish to keep the MalwareDB data.
```

