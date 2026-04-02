# Processes And Services

This guide covers process management and `systemd` service administration on Linux servers.

## Processes

A process is a running program instance. Every process has:

- A PID
- A parent process
- An owning user
- CPU and memory usage
- Open files and sockets

## Inspect Running Processes

### Show all processes

```bash
ps aux
ps -ef
```

### Find a process by name

```bash
pgrep nginx
pgrep -a python
ps aux | grep nginx
```

Prefer `pgrep` when available because it avoids matching the `grep` process itself.

### Interactive views

```bash
top
htop
```

### Sort by CPU or memory

```bash
ps aux --sort=-%cpu | head
ps aux --sort=-%mem | head
```

## Sending Signals

### Graceful termination

```bash
kill <pid>
kill -TERM <pid>
```

### Force termination

```bash
kill -KILL <pid>
kill -9 <pid>
```

Use `SIGKILL` only when graceful shutdown fails because the process cannot clean up.

### Kill by name

```bash
pkill nginx
pkill -f "gunicorn.*myapp"
```

## Foreground And Background Jobs

```bash
command &
jobs
fg %1
bg %1
nohup command > app.log 2>&1 &
```

For production services, prefer `systemd` instead of running long-lived processes with `nohup`.

## Inspect Resource Usage

### CPU and memory

```bash
top
ps aux --sort=-%cpu | head
free -h
vmstat 1 5
```

### Open files

```bash
lsof -p <pid>
lsof /var/log/syslog
```

### Ports owned by processes

```bash
sudo ss -tulpn
sudo lsof -i :443
```

## `systemd` Basics

Most modern Linux distributions use `systemd` to manage services.

### Check service status

```bash
systemctl status nginx
systemctl status ssh
```

### Start, stop, restart, reload

```bash
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo systemctl reload nginx
```

Use `reload` when supported to apply configuration without a full restart.

### Enable or disable at boot

```bash
sudo systemctl enable nginx
sudo systemctl disable nginx
```

### List units

```bash
systemctl list-units --type=service
systemctl list-unit-files --type=service
```

## Logs With `journalctl`

### Show recent logs for a service

```bash
journalctl -u nginx -n 100 --no-pager
```

### Follow logs live

```bash
journalctl -u nginx -f
```

### Show logs since boot or a point in time

```bash
journalctl -b
journalctl -u myapp --since "1 hour ago"
```

## Unit Files

Custom service files usually live in:

- `/etc/systemd/system/`
- `/usr/lib/systemd/system/` or `/lib/systemd/system/` depending on distro

### Example service

```ini
[Unit]
Description=My App
After=network.target

[Service]
User=myapp
Group=myapp
WorkingDirectory=/opt/myapp
ExecStart=/opt/myapp/bin/start.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### Reload after unit changes

```bash
sudo systemctl daemon-reload
sudo systemctl restart myapp
```

If the unit file changed and `daemon-reload` is skipped, `systemd` may continue using stale metadata.

## Startup And Boot Diagnostics

```bash
systemctl --failed
journalctl -p err -b
systemd-analyze
systemd-analyze blame
```

These are useful when a host boots slowly or services fail during startup.

## Best Practices

- Run applications under dedicated service accounts, not as `root`.
- Prefer `systemd` units over ad hoc background processes.
- Use `Restart=always` or `Restart=on-failure` for long-running services where appropriate.
- Capture logs through stdout and stderr so `journalctl` can collect them.
- Test configuration before restart when supported, for example `nginx -t`.
- Use graceful signals and reloads before force-killing processes.
