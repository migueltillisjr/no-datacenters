# Langfuse self-hosted setup

This directory contains a local Langfuse deployment outside the harness
directories. It uses the Langfuse v4 Docker images and supporting PostgreSQL,
ClickHouse, Redis, and MinIO containers.

## Requirements

- Docker Desktop with Docker Compose
- At least 4 CPU cores and 16 GB RAM recommended for the full local stack

## Configure and start

From this directory:

```bash
cp .env.example .env
openssl rand -hex 32
```

Replace every `CHANGEME` value in `.env`. Set `ENCRYPTION_KEY` to the generated
64-character hexadecimal value. The `start.sh` script validates that all
required values are present, strictly validates the encryption key, and checks
the Compose configuration before starting any containers. It warns if other
credentials still use placeholders:

```bash
./start.sh
```

The local single-node setup keeps `CLICKHOUSE_CLUSTER_ENABLED=false`; do not
enable ClickHouse clustering unless you also configure ZooKeeper or ClickHouse
Keeper.

Open [http://localhost:3000](http://localhost:3000), create the first user,
and create a Langfuse organization and project. Langfuse does not provide a
default login.

## Container operations

```bash
docker compose --env-file .env ps
docker compose --env-file .env logs -f langfuse-web
./stop.sh
```

`./stop.sh` stops the containers but preserves named data volumes. To remove
the data volumes as well, use `docker compose --env-file .env down -v` only
when that data can be discarded.

The default setup binds the Langfuse UI to `127.0.0.1:3000` and MinIO to
`127.0.0.1:9090`/`9091`; it is intended for local development and testing,
not high-availability production use.
