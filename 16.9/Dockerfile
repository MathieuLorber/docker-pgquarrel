FROM postgres:16.9

# thanks to https://github.com/eulerto/pgquarrel/issues/54
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates git cmake make gcc libpq-dev postgresql-server-dev-16 \
    && git clone https://github.com/eulerto/pgquarrel.git /tmp/pgquarrel \
    && cd /tmp/pgquarrel \
    && git checkout pgquarrel_0_7_0 \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr/local . \
    && make \
    && make install \
    && rm -rf /tmp/pgquarrel \
    && apt-get purge -y git cmake make gcc postgresql-server-dev-16 \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["pgquarrel"]
