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

Replace every `CHANGEME` value in `.env`. Use the generated 64-character value
for `ENCRYPTION_KEY`, then start the containers:

```bash
./start.sh
```

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
