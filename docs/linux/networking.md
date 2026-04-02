# Linux Networking

This guide covers the Linux networking checks and commands used most often during server administration and incident response.

## Core Concepts

- An interface is a network device such as `eth0`, `ens18`, or `lo`.
- An IP address identifies a host on a network.
- A route tells the kernel where to send packets.
- DNS resolves names such as `api.example.com` into IP addresses.
- A listening socket is a process waiting for inbound traffic on a port.

## Inspect Interfaces And Addresses

### Show IP addresses

```bash
ip addr show
ip -brief address
```

### Show routes

```bash
ip route
ip route get 1.1.1.1
```

`ip route get` is useful to see which interface and source address will be used for a destination.

### Show link status

```bash
ip link show
```

## DNS Checks

### Resolve a hostname

```bash
getent hosts example.com
dig example.com
dig +short example.com
nslookup example.com
```

Prefer `dig` or `getent hosts` for reliable diagnostics.

### Query a specific DNS server

```bash
dig @1.1.1.1 example.com
dig @8.8.8.8 example.com MX
```

### Check resolver configuration

```bash
cat /etc/resolv.conf
resolvectl status
```

On newer systems using `systemd-resolved`, `resolvectl` is often the fastest way to inspect DNS state.

## Connectivity Tests

### Ping a host

```bash
ping -c 4 8.8.8.8
ping -c 4 example.com
```

If ping by IP works but ping by name fails, the likely issue is DNS.

### Test a TCP port

```bash
nc -vz example.com 443
telnet example.com 443
curl -v https://example.com
```

`nc` is preferred over `telnet` when available.

### Trace the path to a host

```bash
traceroute example.com
tracepath example.com
mtr -rw example.com
```

`mtr` is usually the most informative tool because it combines latency and packet loss over time.

## Listening Ports And Connections

### Show listening sockets

```bash
ss -tulpn
sudo ss -tulpn | grep ':80'
```

### Show active connections

```bash
ss -tan
ss -uan
```

Useful flags:

- `-t` TCP
- `-u` UDP
- `-l` listening
- `-p` process
- `-n` numeric output

## Firewall Basics

### `ufw` on Ubuntu

```bash
sudo ufw status verbose
sudo ufw allow 22/tcp
sudo ufw allow 80,443/tcp
```

### `firewalld` on RHEL-family systems

```bash
sudo firewall-cmd --state
sudo firewall-cmd --list-all
sudo firewall-cmd --add-service=https --permanent
sudo firewall-cmd --reload
```

### Inspect packet filtering rules directly

```bash
sudo nft list ruleset
sudo iptables -S
```

Modern distributions increasingly use `nftables`, even if compatibility commands still reference iptables.

## Common HTTP Diagnostics

### Request headers only

```bash
curl -I https://example.com
```

### Make a verbose request

```bash
curl -v https://example.com
```

### Test a local service with a custom Host header

```bash
curl -H "Host: app.example.com" http://127.0.0.1
```

This is useful when validating reverse proxy or virtual host configuration.

## Useful Files

- `/etc/hosts` static hostname mappings
- `/etc/resolv.conf` DNS resolver settings
- `/etc/netplan/` Ubuntu network configuration on newer releases
- `/etc/network/interfaces` older Debian and Ubuntu network configuration
- `/etc/ssh/sshd_config` SSH daemon settings

## Troubleshooting Patterns

### Service is unreachable

Check in this order:

1. Is the process running: `systemctl status nginx`
2. Is the port listening: `ss -tulpn | grep ':80'`
3. Is the firewall allowing traffic: `ufw status` or `firewall-cmd --list-all`
4. Is DNS resolving correctly: `dig +short app.example.com`
5. Is routing correct: `ip route`

### DNS looks broken

Check:

1. `/etc/resolv.conf`
2. `resolvectl status`
3. `dig @resolver-ip hostname`
4. `getent hosts hostname`

### Host can reach the internet by IP but not by name

This almost always points to DNS misconfiguration rather than a general network failure.

## Best Practices

- Prefer `ss`, `ip`, `dig`, `curl`, and `mtr` over older tools when available.
- Keep host firewalls enabled and open only required ports.
- Validate from both the local host and a remote client when debugging reachability.
- Separate DNS issues, routing issues, firewall issues, and application issues instead of treating them as one problem.
- Avoid changing network configuration during an incident without first capturing the current state with `ip addr`, `ip route`, and firewall output.
