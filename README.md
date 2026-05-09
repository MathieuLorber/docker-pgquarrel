# docker-pgquarrel

Builds a public Docker image of [pgquarrel](https://github.com/eulerto/pgquarrel)
with an `ENTRYPOINT` so the image is callable like a command. Used by
`DockerPgquarrel` (in `database-lib`) to diff PostgreSQL schemas across
environments.

## Image

Published as `mlorber/public:pgquarrel-compare-<sha>-pg<version>`.

The `<sha>` is the short commit SHA of the pinned pgquarrel revision, and
`<version>` is the postgres base image (matters because libpq embedded in the
image determines what server versions pgquarrel can talk to).

A mutable `mlorber/public:pgquarrel-compare` tag is also pushed for
human/CLI convenience. Production code (`DockerPgquarrel.image`) always
pins to the immutable SHA-tagged variant.

## Why master and not the 0.7.0 tag

The `pgquarrel_0_7_0` tag (March 2023) does **not** compile against PG14+
headers. It calls `simple_prompt(prompt, buf, len, echo)` (4 args), but PG14
changed the signature to `simple_prompt(prompt, echo)` (2 args). Master gates
the call with `#if PG_VERSION_NUM >= 140000` and compiles cleanly on PG14
through PG18.

We pin to a specific master commit so the build is reproducible.

## Why dev headers must match the runtime base

Two pitfalls aligned:

1. `postgresql-server-dev-all` (a meta package) makes `pg_config` resolve to
   whichever pg-dev was installed last by apt. The Debian repos started
   shipping pg18-dev recently, which silently changed everything. We pin to
   `postgresql-server-dev-18` explicitly to match the `postgres:18.0` runtime
   base.
2. pgquarrel checks the server version at connect time and **refuses** to
   talk to a server newer than the PG version it was compiled against
   (`cannot connect to server whose version (X.Y) is greater than postgres
   version (Z.W) used to compile pgquarrel`). So the dev headers used at
   build time must be ≥ the highest PG server version pgquarrel will face at
   runtime.

If you bump the postgres base, also bump `postgresql-server-dev-NN` in the
Dockerfile and the `pg<version>` suffix in the image tag.

## Build & push (multi-arch)

The image is consumed both on Apple Silicon dev machines (arm64) and on CI
or Linux servers (amd64). It must be a multi-arch manifest, otherwise
pulling on the wrong arch fails or silently runs under emulation.

```bash
# One-time
docker login
docker buildx create --use --name multiarch

# Each release
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t mlorber/public:pgquarrel-compare-<sha>-pg<version> \
  -t mlorber/public:pgquarrel-compare \
  --push \
  docker-pgquarrel
```

After a push, update `DockerPgquarrel.image` in `database-lib` to point at
the new immutable tag.
