MAINTAINER Richard Zak <info@malwaredb.net>
LABEL SOURCE="https://github.com/malwaredb/"
EXPOSE 8080
FROM debian:bookworm

# Install things we need for compilation
RUN apt-get update && apt-get dist-upgrade -y
RUN apt-get install -y postgresql-15 postgresql-server-dev-15 sudo libfuzzy2 libfuzzy-dev cmake make build-essential git curl libssl-dev libgomp1
RUN apt-get install -y protobuf-c-compiler protobuf-compiler libprotobuf-c-dev libprotobuf-c1 libprotobuf-dev libprotobuf32 libcrypt-dev libcrypt1
RUN apt-get install -y libboost-program-options-dev libboost-filesystem-dev libboost-system-dev libboost-program-options1.74.0 libboost-filesystem1.74.0 libboost-system1.74.0

# Install Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Download the components
RUN git clone https://github.com/malwaredb/malwaredb-rs.git
RUN git clone https://github.com/malwaredb/LZJD.git
RUN git clone https://github.com/malwaredb/ssdeep_psql.git
RUN git clone --recursive https://github.com/malwaredb/tlsh_pg.git
RUN git clone --recursive https://github.com/malwaredb/sdhash_psql.git

# Compile, Install, and Delete sources for MalwareDB
RUN cd malwaredb-rs && . $HOME/.cargo/env && cargo build --release && cp target/release/mdb_server /usr/bin/
RUN rm -rf malwaredb-rs

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

# End: cleanup
# Don't need to bloat the image with development tools once we're done with them
RUN apt-get remove -y postgresql-server-dev-15 libfuzzy-dev cmake make build-essential git curl
RUN apt-get remove -y libboost-program-options-dev libboost-filesystem-dev libboost-system-dev libprotobuf-c-dev libprotobuf-dev libcrypt-dev
RUN apt-get autoremove -y

# Create some directories for MalwareDB's data
RUN mkdir /malwaredb
RUN mkdir /malwaredb/database && chown postgres:postgres /malwaredb/database
RUN mkdir /malwaredb/samples

# Setup Postgres
RUN /etc/init.d/postgresql start && sudo -u postgres psql --command "CREATE USER malwaredb WITH PASSWORD 'malwaredb';" && \
  sudo -u postgres psql --command "CREATE TABLESPACE malwaredb OWNER malwaredb LOCATION '/malwaredb/database';" && \
  sudo -u postgres psql --command "CREATE DATABASE malwaredb OWNER malwaredb TABLESPACE 'malwaredb';" && \
# Add extensions
  sudo -u postgres psql --command "CREATE OR REPLACE FUNCTION fuzzy_hash_compare(TEXT, TEXT) RETURNS INTEGER AS 'ssdeep_psql.so', 'pg_fuzzy_hash_compare' LANGUAGE 'c';" && \
  sudo -u postgres psql --command "CREATE OR REPLACE FUNCTION tlsh_compare(TEXT, TEXT) RETURNS INTEGER AS 'tlsh_psql.so', 'pg_tlsh_compare' LANGUAGE 'c';" && \
  sudo -u postgres psql --command "CREATE OR REPLACE FUNCTION sdhash_compare(TEXT, TEXT) RETURNS INTEGER AS 'sdhash_psql.so', 'pg_sdhash_compare' LANGUAGE 'c';" && \
  sudo -u postgres psql --command "CREATE OR REPLACE FUNCTION lzjd_compare(TEXT, TEXT) RETURNS INTEGER AS 'lzjd_psql.so', 'pg_lzjd_compare' LANGUAGE 'c';"

# Start MalwareDB
ENTRYPOINT ["/usr/bin/mdb_server", "run", "config", "-p", "8080", "--dir", "/malwaredb/samples", "--db", "postgres user=malwaredb password=malwaredb dbname=malwaredb host=localhost", "-m", "1 GB"]