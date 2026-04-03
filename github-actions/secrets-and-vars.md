# Secrets and Variables

This repository uses **GitHub Environment** secrets and variables for `deploy.yml`.

Open GitHub:
`Repository -> Settings -> Environments -> <your-environment>`

Add these **Environment secrets**:

- `SSH_HOST`: hostname or public IP of the target server.
- `SSH_PORT`: SSH port of the target server, usually `22`.
- `SSH_USER`: Linux user used for deployment.
- `SSH_PRIVATE_KEY`: private key for that user. Generate with `ssh-keygen -t ed25519`, then copy the content of the private key file.
- `SSH_KNOWN_HOSTS`: server host key entry. Get it with:

```bash
ssh-keyscan -p 22 your-server.example.com
```

If you use a custom SSH port, replace `22` with the real one.

Add these **Environment variables**:

- `DEPLOY_PATH`: absolute path on the server where the repository is located, for example `/opt/my-app`.
- `COMPOSE_FILE`: docker compose file used for deployment, for example `docker-compose.prod.yml`.

Notes:

- The `ci.yml` workflow does not require any secrets or variables.
- The deploy workflow checks out the selected branch on the server and runs `docker compose -f $COMPOSE_FILE up -d --build`.
- The public key matching `SSH_PRIVATE_KEY` must already be present in `~/.ssh/authorized_keys` for `SSH_USER` on the target server.
