# Systemd Services For Deployments

This guide explains how to run application processes as `systemd` services on Linux servers.

## Why Use `systemd`

`systemd` gives you:

- service startup at boot
- automatic restarts
- centralized logs with `journalctl`
- dependency ordering
- consistent operational commands

For long-running services on a Linux host, `systemd` is the default baseline.

## Unit File Location

Custom units typically live in:

```bash
/etc/systemd/system/
```

Packaged service units may live under:

- `/lib/systemd/system/`
- `/usr/lib/systemd/system/`

## Example Application Service

```ini
[Unit]
Description=My App API
After=network.target

[Service]
Type=simple
User=myapp
Group=myapp
WorkingDirectory=/opt/myapp/current
EnvironmentFile=/etc/myapp/myapp.env
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
```

Save as:

```bash
/etc/systemd/system/myapp.service
```

## Environment Files

Store config outside the app directory where practical:

```bash
/etc/myapp/myapp.env
```

Example:

```env
PORT=3000
NODE_ENV=production
DATABASE_URL=postgres://user:pass@db.internal/app
```

Protect secrets:

```bash
sudo chown root:myapp /etc/myapp/myapp.env
sudo chmod 640 /etc/myapp/myapp.env
```

## Dedicated Service User

Create a least-privilege runtime user:

```bash
sudo useradd --system --home /opt/myapp --shell /usr/sbin/nologin myapp
sudo chown -R myapp:myapp /opt/myapp
```

Avoid running application processes as `root`.

## Enable And Start

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now myapp
systemctl status myapp
```

## Day-To-Day Commands

```bash
sudo systemctl start myapp
sudo systemctl stop myapp
sudo systemctl restart myapp
sudo systemctl reload myapp
sudo systemctl status myapp
```

Only use `reload` if the application actually supports config reload behavior.

## Logs

View logs:

```bash
journalctl -u myapp -n 100 --no-pager
journalctl -u myapp -f
```

Applications that write to stdout and stderr work well with journald.

## Deploy Update Flow

A simple deployment sequence:

1. Upload the new release
2. Update symlink or working directory target
3. Validate config
4. Restart the service
5. Confirm health

Example:

```bash
sudo systemctl restart myapp
systemctl status myapp
curl -f http://127.0.0.1:3000/health
```

## Service Hardening

Useful hardening directives:

```ini
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/myapp /var/lib/myapp
```

Do not copy all hardening options blindly. Some applications need filesystem or network capabilities that stricter settings can block.

## Restart Policies

Common choices:

- `Restart=always` for long-running daemons
- `Restart=on-failure` when you want clean exits to stay stopped

Add a short delay:

```ini
RestartSec=5
```

This helps avoid tight crash loops.

## Ordering And Dependencies

If the app depends on network availability:

```ini
After=network-online.target
Wants=network-online.target
```

If it depends on a local database or another service, model that explicitly where appropriate.

## Timers For Scheduled Tasks

For cron-like scheduled jobs, prefer `systemd` timers when you want the same tooling and observability model.

Example components:

- `myapp-backup.service`
- `myapp-backup.timer`

## Troubleshooting

### Service fails to start

Check:

```bash
systemctl status myapp
journalctl -u myapp -n 100 --no-pager
```

Common causes:

- bad `ExecStart` path
- missing environment file
- wrong working directory
- permission issue on app files
- port already in use

### Unit file changed but behavior did not

Run:

```bash
sudo systemctl daemon-reload
```

### Service starts manually but not under `systemd`

Compare:

- working directory
- environment variables
- PATH assumptions
- file permissions
- service user identity

## Best Practices

- Use a dedicated service account and an external environment file.
- Keep unit files small and explicit.
- Write app logs to stdout and stderr for `journalctl`.
- Validate the service after every deployment with `systemctl status` and a health check.
- Use `daemon-reload` after unit changes and before restart.
