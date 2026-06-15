FROM postgres:18.0

# thanks to https://github.com/eulerto/pgquarrel/issues/54
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates git cmake make gcc libpq-dev postgresql-server-dev-18 \
    && git clone https://github.com/eulerto/pgquarrel.git /tmp/pgquarrel \
    && cd /tmp/pgquarrel \
    && git checkout 80637e44afc68fa226aad8fb90b2cab7c24a39c4 \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr/local . \
    && make \
    && make install \
    && rm -rf /tmp/pgquarrel \
    && apt-get purge -y git cmake make gcc postgresql-server-dev-18 \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["pgquarrel"]
