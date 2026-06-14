# docker-pgquarrel

Builds public, multi-arch Docker images of
[pgquarrel](https://github.com/eulerto/pgquarrel) with an `ENTRYPOINT` so the
image is callable like a command. Used by `DockerPgquarrel` in
[ktts-webapp-sample]'s `database-lib` to diff PostgreSQL schemas across
environments.

## Layout

One sub-directory per PostgreSQL base version:

```
16.9/Dockerfile   16.9/push.sh
18.0/Dockerfile   18.0/push.sh
```

Each version produces its own image tag. Multiple versions coexist because
**pgquarrel is bound at compile time to the PG headers it was built against**:
the `postgresql-server-dev-NN` package determines which server versions the
resulting binary can talk to (see [Version coupling](#version-coupling) below).

## Image naming

```
mlorber/public:pgquarrel-compare-<pgquarrel-ref>-pg<pg-version>
```

- `<pgquarrel-ref>` — either a short SHA of a master commit (e.g. `80637e4`) or
  a release tag in slug form (e.g. `0_7_0`).
- `<pg-version>` — the `postgres:NN.M` base image tag (e.g. `18.0`).

Examples produced by this repo:

| Subdir   | pgquarrel ref       | Image tag                                        |
| -------- | ------------------- | ------------------------------------------------ |
| `18.0/`  | master `80637e4`    | `mlorber/public:pgquarrel-compare-80637e4-pg18.0` |
| `16.9/`  | tag `pgquarrel_0_7_0` | `mlorber/public:pgquarrel-compare-0_7_0-pg16.9`   |

Production code (`DockerPgquarrel.image` in ktts-webapp-sample) always pins to
one of these immutable tags.

## Which pgquarrel ref to pick

- **PG14+ base** → use a **master** commit. The `pgquarrel_0_7_0` release
  (March 2023) calls `simple_prompt(prompt, buf, len, echo)` (4 args), but
  PG14 changed the signature to `simple_prompt(prompt, echo)` (2 args).
  Master gates the call with `#if PG_VERSION_NUM >= 140000` and compiles
  cleanly on PG14 through PG18.
- **PG13 and earlier** → either master or the `pgquarrel_0_7_0` tag work; the
  tag is preferable when you want an immutable release as the source of truth.

Pin to a specific SHA either way so the build is reproducible.

> Note: the current `16.9/Dockerfile` uses `pgquarrel_0_7_0` against
> `postgresql-server-dev-16` — verify it actually builds before pushing
> (the rule above says master would be the safer pick on PG14+).

## Version coupling

Two pitfalls aligned, both fixed by the same rule: **the
`postgresql-server-dev-NN` you install at build time must match the
`postgres:NN.M` base**:

1. `postgresql-server-dev-all` (a meta package) makes `pg_config` resolve to
   whichever pg-dev was installed last by apt. The Debian repos started
   shipping pg18-dev recently, which silently changes the build. Pin
   `postgresql-server-dev-NN` explicitly.
2. pgquarrel checks the server version at connect time and **refuses** to talk
   to a server newer than the PG version it was compiled against:

   > cannot connect to server whose version (X.Y) is greater than postgres
   > version (Z.W) used to compile pgquarrel

   So a `pg18.0` image can connect to PG ≤ 18; a `pg16.9` image can connect to
   PG ≤ 16. Pick the image that covers the *newest* server you need to diff.

## Build & push (multi-arch)

The image must be a multi-arch manifest — it's consumed both on Apple Silicon
dev machines (arm64) and on CI/Linux servers (amd64).

```bash
# One-time
docker login
docker buildx create --use --name multiarch

# Build & push a version (the context is the subdir)
cd 18.0
./push.sh
```

`push.sh` in each subdir is hardcoded for that version's image tag. To bump a
version in place, edit `Dockerfile` and `push.sh` together and re-run.

## Adding a new PostgreSQL version

1. `cp -r 18.0 NEW_VERSION` (e.g. `19.0`).
2. In `NEW_VERSION/Dockerfile`:
   - Update `FROM postgres:NEW_VERSION`.
   - Update `postgresql-server-dev-NN` (and the matching `apt-get purge` line).
   - Pick the pgquarrel ref per [Which pgquarrel ref to pick](#which-pgquarrel-ref-to-pick).
3. In `NEW_VERSION/push.sh`, update the image tag (`-pgNEW_VERSION` suffix and
   the pgquarrel ref slug).
4. `cd NEW_VERSION && ./push.sh`.
5. Update `DockerPgquarrel.image` in [ktts-webapp-sample] to point at the new
   immutable tag.

[ktts-webapp-sample]: https://github.com/MathieuLorber/ktts-webapp-sample
