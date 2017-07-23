FROM percona

ARG version=zero
ARG branch=master

RUN apt-get update && \
    apt-get -y install git && \
    rm -rf /var/lib/apt/lists/*

RUN git clone http://github.com/mangos${version}/database.git "/tmp/database" -b $branch --recursive

ADD import-db.sh /docker-entrypoint-initdb.d
