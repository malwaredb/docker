FROM debian:trixie-slim@sha256:4bcb9db66237237d03b55b969271728dd3d955eaaa254b9db8a3db94550b1885 AS builder
LABEL MAINTAINER="Richard Zak <richard@malwaredb.net>"
LABEL org.opencontainers.image.authors=richard@malwaredb.net
LABEL SOURCE="https://github.com/malwaredb/docker/"
LABEL org.opencontainers.image.source=https://github.com/malwaredb/docker/
LABEL org.opencontainers.image.description="Postgres 18 on Debian Trixie with similarity extensions installed intended for use with MalwareDB"
LABEL org.opencontainers.image.licenses=Apache-2.0
ENV DEBIAN_FRONTEND=noninteractive

# Install things we need for compilation
RUN apt-get update && apt-get dist-upgrade -y
RUN apt-get install -y postgresql-17 postgresql-server-dev-17 libfuzzy2 libfuzzy-dev cmake make build-essential git curl libssl-dev libssl3 libgomp1
RUN apt-get install -y libboost-program-options-dev libboost-filesystem-dev libboost-system-dev libboost-program-options-dev

# Download the components
WORKDIR /malwaredb_pg
RUN git clone https://github.com/malwaredb/LZJD.git
RUN git clone https://github.com/malwaredb/ssdeep_psql.git
RUN git clone --recursive https://github.com/malwaredb/tlsh_pg.git

# Compile LZJD, SSDeep, TLSH plugins
RUN cd LZJD/src/ && mkdir build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release && make
RUN cd ssdeep_psql && make
RUN cd tlsh_pg/tlsh && ./make.sh && cd .. && mkdir build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release && make
RUN ls -lah /malwaredb_pg

FROM postgres:18-trixie@sha256:bfe50b2b0ddd9b55eadedd066fe24c7c6fe06626185b73358c480ea37868024d
RUN apt-get update && apt-get install -y libfuzzy2

WORKDIR /malwaredb_pg
COPY --from=builder /malwaredb_pg/LZJD/src/build/lzjd_psql.so /malwaredb_pg
COPY --from=builder /malwaredb_pg/ssdeep_psql/ssdeep_psql.so /malwaredb_pg
COPY --from=builder /malwaredb_pg/tlsh_pg/build/tlsh_psql.so /malwaredb_pg
RUN ls -lah /malwaredb_pg && cp /malwaredb_pg/lzjd_psql.so /malwaredb_pg/ssdeep_psql.so /malwaredb_pg/tlsh_psql.so `pg_config --pkglibdir`

VOLUME /var/lib/postgresql/18/data/
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# For fast shutdown mode for Postgres
# https://github.com/docker-library/postgres/blob/dd68d91377a3631b36a23f2e4795f6189db4ba12/15/bullseye/Dockerfile#L188
STOPSIGNAL SIGINT
EXPOSE 5432/tcp

CMD ["postgres"]
