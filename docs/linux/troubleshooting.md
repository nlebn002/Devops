# Linux Troubleshooting

This guide provides a practical workflow for diagnosing Linux server issues without making the situation worse.

## General Approach

Troubleshooting is faster when you separate symptoms into clear categories:

- Host unreachable
- Service down
- High CPU or memory
- Disk full
- DNS or network problems
- Permission failures
- Recent change regression

Start by collecting facts before changing configuration.

## First Checks

### Identify the host and OS

```bash
hostnamectl
uname -a
cat /etc/os-release
uptime
date
```

### Check recent login or shell history if relevant

```bash
last -n 10
history | tail -n 20
```

Do not assume history is complete or trustworthy on multi-user systems.

## Service Health

```bash
systemctl --failed
systemctl status nginx
journalctl -u nginx -n 100 --no-pager
```

If a service will not start, always inspect logs before retrying restarts repeatedly.

## Resource Pressure

### CPU

```bash
uptime
top
ps aux --sort=-%cpu | head
```

### Memory

```bash
free -h
vmstat 1 5
ps aux --sort=-%mem | head
```

### Disk

```bash
df -h
df -i
du -xhd1 / | sort -h
```

### Deleted files still consuming space

```bash
sudo lsof +L1
```

## Networking

```bash
ip addr
ip route
ss -tulpn
curl -I http://127.0.0.1
dig +short example.com
ping -c 4 8.8.8.8
```

Keep the checks layered:

1. Local process
2. Local port
3. Host firewall
4. Routing
5. DNS
6. Remote access path

## Logs

### System journal

```bash
journalctl -b -p warning
journalctl -xe
```

### Kernel messages

```bash
dmesg -T | tail -n 50
journalctl -k -p warning
```

### Traditional logs

```bash
less /var/log/syslog
less /var/log/messages
less /var/log/auth.log
less /var/log/secure
```

Log file names vary by distribution.

## Configuration Validation

Before restarting services, validate configuration when possible:

```bash
sudo nginx -t
sudo sshd -t
sudo apachectl configtest
sudo mount -a
```

This avoids turning a partial outage into a full outage.

## Package And Update Issues

### Debian and Ubuntu

```bash
sudo apt update
sudo apt --fix-broken install
sudo dpkg --configure -a
```

### RHEL-family

```bash
sudo dnf check
sudo dnf repolist
sudo dnf history
```

## Boot Problems

```bash
systemctl --failed
journalctl -b -1
systemd-analyze blame
```

`journalctl -b -1` is especially useful after a failed previous boot.

## Common Incident Patterns

### Web app returns `502` or `504`

Check:

1. Reverse proxy is running
2. Upstream app is running
3. Upstream socket or port is listening
4. App logs and proxy logs
5. Firewall and SELinux or AppArmor if relevant

### SSH stopped working

Check:

1. Host reachable by IP
2. Port 22 listening: `ss -tulpn | grep ':22'`
3. Firewall rules
4. `sshd` config test: `sshd -t`
5. Auth logs: `/var/log/auth.log` or `/var/log/secure`

### Disk full

Check:

1. `df -h`
2. `df -i`
3. `du -xhd1 /`
4. `lsof +L1`
5. Log rotation status

### High load average

Check:

1. CPU saturation in `top`
2. I/O wait in `vmstat`
3. Blocked services
4. Slow storage or NFS mounts

## Change Tracking

When something broke recently, compare against recent changes:

- package upgrades
- config deploys
- certificate renewals
- DNS changes
- firewall changes
- disk growth

Useful commands:

```bash
last reboot
journalctl --since "2 hours ago"
grep -Rni "changed-setting" /etc
```

## Best Practices

- Capture the current state before editing files or restarting services.
- Change one variable at a time when isolating a fault.
- Validate configs before reload or restart.
- Prefer reversible actions first.
- Record timestamps and exact commands during incidents.
- If the impact is high, preserve logs and evidence before cleanup.
