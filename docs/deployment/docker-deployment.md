# Docker Deployment

This guide covers practical Docker deployment patterns for a single Linux host or small VPS setup.

## When Docker Fits Well

Docker is a good fit when you want:

- consistent packaging across environments
- simpler dependency isolation
- easier rollbacks through image tags
- predictable runtime configuration

It is less effective when teams treat containers as a substitute for basic operational discipline. Logging, updates, secrets, and monitoring still need design.

## Core Components

- Docker Engine runs containers
- images package the app and dependencies
- containers run images
- volumes persist data
- networks connect containers
- Docker Compose defines multi-container applications

## Install Docker

Use Docker's official repository for current packages.

High-level flow:

1. install repository prerequisites
2. add Docker GPG key
3. add the Docker apt repository
4. install Docker packages
5. enable the Docker service

Verify:

```bash
docker version
docker info
systemctl status docker
```

## Example Compose Layout

Common host structure:

```text
/opt/myapp/
  compose.yaml
  .env
  nginx.conf
```

## Example `compose.yaml`

```yaml
services:
  app:
    image: ghcr.io/example/myapp:1.0.0
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - "127.0.0.1:3000:3000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://127.0.0.1:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3

  nginx:
    image: nginx:stable
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
    depends_on:
      - app
```

This keeps the application private on localhost while Nginx handles public traffic.

## Image Strategy

Use immutable tags for deploys:

- `1.4.2`
- commit SHA tags

Avoid deploying production with only `latest`. It makes rollback and incident analysis weaker.

## Deploy Flow

Typical flow:

1. build image in CI
2. push image to a registry
3. pull the new tag on the server
4. restart only the affected services
5. verify health and logs

Example:

```bash
cd /opt/myapp
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --tail=100
```

## Environment Variables

Example `.env`:

```env
APP_ENV=production
APP_PORT=3000
DATABASE_URL=postgres://user:pass@db:5432/app
```

Protect env files because they often contain secrets:

```bash
chmod 600 .env
```

For stronger separation, use an external secret manager instead of long-lived secrets in local files.

## Persistent Data

Use named volumes or bind mounts for stateful services:

```yaml
volumes:
  postgres-data:
```

Do not store important database state only inside the writable container layer.

## Logs

Useful commands:

```bash
docker compose logs -f
docker compose logs app
docker logs <container-id>
```

Plan for log rotation on the host if container logs are written to local disk through the default logging driver.

## Health Checks

A container being "up" does not always mean the application is healthy.

Use:

- Docker health checks
- HTTP health endpoints
- external monitoring

## Reverse Proxy Pattern

Common small-host pattern:

1. App container listens on internal port `3000`
2. Nginx container or host Nginx handles `80` and `443`
3. TLS terminates at the proxy
4. Proxy forwards to the app over an internal network or localhost binding

## Backup Considerations

Back up:

- environment files if they are part of runtime config
- compose files
- mounted application config
- persistent volumes or the underlying database

Do not assume rebuilding containers is enough if data lives in volumes.

## Security Notes

- Run containers with the minimum privileges required.
- Avoid `--privileged` unless there is a very clear reason.
- Keep images small and current.
- Scan images in CI if possible.
- Limit published ports to only what must be public.

## Troubleshooting

### Container restarts repeatedly

Check:

```bash
docker compose ps
docker compose logs app --tail=100
docker inspect <container-id>
```

### Port binding fails

Check:

```bash
sudo ss -tulpn | grep ':80'
sudo ss -tulpn | grep ':443'
```

### New deploy is running but traffic still fails

Check:

1. container health
2. reverse proxy config
3. firewall rules
4. app listening address
5. image tag in the running compose config

## Best Practices

- Use pinned image tags and keep deploys reproducible.
- Publish only required ports, ideally with Nginx or another proxy in front.
- Add health checks and verify them after deploy.
- Store persistent data in volumes or managed services, not ephemeral containers.
- Treat Compose files, env files, and registry credentials as controlled deployment assets.
