FROM postgres:10

RUN apt update && apt -y install curl vim procps && \
  cd /tmp && curl -OL https://github.com/wal-g/wal-g/releases/download/v0.2.17/wal-g.linux-amd64.tar.gz && \
  tar zxvf wal-g.linux-amd64.tar.gz && rm wal-g.linux-amd64.tar.gz && mv wal-g /usr/local/bin

RUN curl -OL https://dl.min.io/client/mc/release/linux-amd64/mc && chmod a+x mc && mv mc /usr/local/bin/
