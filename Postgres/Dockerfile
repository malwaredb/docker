FROM debian:bookworm-slim
MAINTAINER Richard Zak <info@malwaredb.net>
LABEL SOURCE="https://github.com/malwaredb/"

# Install things we need for compilation
RUN apt-get update && apt-get dist-upgrade -y
RUN apt-get install -y postgresql-15 postgresql-server-dev-15 sudo libfuzzy2 libfuzzy-dev cmake make build-essential git curl libssl-dev libssl3 libgomp1
RUN apt-get install -y protobuf-c-compiler protobuf-compiler libprotobuf-c-dev libprotobuf-c1 libprotobuf-dev libprotoc32 libprotobuf32 libcrypt-dev libcrypt1
RUN apt-get install -y libboost-program-options-dev libboost-filesystem-dev libboost-system-dev libboost-program-options1.74.0 libboost-filesystem1.74.0 libboost-system1.74.0

# Download the components
RUN git clone https://github.com/malwaredb/LZJD.git
RUN git clone https://github.com/malwaredb/ssdeep_psql.git
RUN git clone --recursive https://github.com/malwaredb/tlsh_pg.git
RUN git clone --recursive https://github.com/malwaredb/sdhash_psql.git

# Compile, Install, and Delete sources for LZJD
RUN cd LZJD/src/ && mkdir build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release && make && cp lzjd_psql.so `pg_config --pkglibdir`
RUN rm -rf LZJD

# Compile, Install, and Delete sources for SSDeep
RUN cd ssdeep_psql && make && make install
RUN rm -rf ssdeep_psql

# Compile, Install, and Delete sources for TLSH
RUN cd tlsh_pg/tlsh && ./make.sh && cd .. && mkdir build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release && make && cp tlsh_psql.so `pg_config --pkglibdir`
RUN rm -rf tlsh_pg

# Compile, Install, and Delete sources for SDHash
RUN cd sdhash_psql/sdhash && make && cd .. && make sdhash_psql.so && make install
RUN rm -rf sdhash_psql

# Get gosu, needed for entrypoint script
# grab gosu for easy step-down from root
# https://github.com/tianon/gosu/releases
ENV GOSU_VERSION 1.16
RUN set -eux; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends ca-certificates wget; \
	rm -rf /var/lib/apt/lists/*; \
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	chmod +x /usr/local/bin/gosu; \
	gosu --version; \
	gosu nobody true

# End: cleanup
# Don't need to bloat the image with development tools once we're done with them
RUN apt-get remove -y postgresql-server-dev-15 libfuzzy-dev cmake make build-essential git curl libssl-dev protobuf-c-compiler protobuf-compiler
RUN apt-get remove -y libboost-program-options-dev libboost-filesystem-dev libboost-system-dev libprotobuf-c-dev libprotobuf-dev libcrypt-dev
RUN apt-get autoremove -y && apt-get clean

# Ensure postgres apps are reachable
ENV PG_MAJOR 15
ENV PATH $PATH:/usr/lib/postgresql/$PG_MAJOR/bin

# Allow external connections
RUN echo "listen_addresses='*'" >> /etc/postgresql/15/main/postgresql.conf

ENV PGDATA /var/lib/postgresql/data
RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 777 "$PGDATA"
VOLUME /var/lib/postgresql/data

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# For fast shutdown mode for Postgres
# https://github.com/docker-library/postgres/blob/dd68d91377a3631b36a23f2e4795f6189db4ba12/15/bullseye/Dockerfile#L188
STOPSIGNAL SIGINT
EXPOSE 5432/tcp

CMD ["postgres"]
