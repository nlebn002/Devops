# Ubuntu Server Setup

This guide covers a baseline setup for an Ubuntu server intended to run application workloads. It focuses on secure defaults, repeatable steps, and operational readiness.

## Goals

- Create a non-root admin user
- Enable key-based SSH access
- Apply updates
- Configure a firewall
- Install core admin tools
- Prepare the host for application deployment

## Assumptions

- Ubuntu Server with `systemd`
- You have initial console access or provider access
- The server has internet connectivity

## 1. Verify Host Basics

```bash
hostnamectl
cat /etc/os-release
ip -brief address
df -h
free -h
```

Set a stable hostname if needed:

```bash
sudo hostnamectl set-hostname app-prod-01
```

## 2. Update The System

```bash
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
```

If the server will host internet-facing workloads, patching early is one of the simplest risk reductions.

## 3. Create An Admin User

```bash
sudo adduser deploy
sudo usermod -aG sudo deploy
```

Verify:

```bash
id deploy
```

Avoid day-to-day administration as `root`.

## 4. Configure SSH Keys

From your local machine:

```bash
ssh-copy-id deploy@server-ip
```

Or manually place the public key in:

```bash
/home/deploy/.ssh/authorized_keys
```

Set permissions:

```bash
sudo mkdir -p /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh
sudo chmod 600 /home/deploy/.ssh/authorized_keys
sudo chown -R deploy:deploy /home/deploy/.ssh
```

Test SSH login in a separate session before changing SSH daemon settings.

## 5. Harden SSH

Edit:

```bash
sudoedit /etc/ssh/sshd_config
```

Common baseline settings:

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
```

Validate and reload:

```bash
sudo sshd -t
sudo systemctl reload ssh
```

On some systems the service may be named `sshd`.

## 6. Configure The Firewall

Ubuntu commonly uses `ufw`.

Allow SSH first:

```bash
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw status verbose
```

Later allow application traffic as needed:

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

Do not enable a firewall rule set that blocks your current SSH access.

## 7. Install Base Packages

Common server tooling:

```bash
sudo apt install -y \
  curl \
  wget \
  git \
  vim \
  htop \
  jq \
  unzip \
  ca-certificates \
  gnupg \
  lsb-release \
  net-tools \
  dnsutils \
  ufw
```

Adjust to your team standard. Avoid installing unnecessary packages on minimal production hosts.

## 8. Configure Time And Locale

Check time sync:

```bash
timedatectl
systemctl status systemd-timesyncd
```

If needed:

```bash
sudo timedatectl set-timezone UTC
```

Using UTC on servers reduces operational confusion across regions.

## 9. Prepare Application Directories

Example layout:

```bash
sudo mkdir -p /opt/myapp
sudo mkdir -p /var/log/myapp
sudo mkdir -p /etc/myapp
sudo chown -R deploy:deploy /opt/myapp /var/log/myapp
```

For shared team environments, consider a dedicated service account rather than reusing the admin user.

## 10. Optional: Install Docker

If the host will run containerized workloads, install Docker from Docker's official repository rather than relying on outdated distribution packages.

High-level flow:

1. Add Docker's repository key
2. Add the Docker apt repository
3. Install `docker-ce`, `docker-ce-cli`, and `containerd.io`
4. Add the deploy user to the `docker` group if appropriate

If using Docker in production, combine it with log rotation, service restart policies, and monitoring.

## 11. Optional: Install Nginx

```bash
sudo apt install -y nginx
sudo systemctl enable --now nginx
systemctl status nginx
```

Validate from the server:

```bash
curl -I http://127.0.0.1
```

## 12. Optional: Automatic Security Updates

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

Use this with care on systems where package changes require strict maintenance windows.

## 13. Verification Checklist

Confirm:

1. You can SSH in as the non-root admin user
2. `sudo` works for that user
3. The firewall allows only required ports
4. The system is updated
5. Time sync is healthy
6. Disk and memory baselines are acceptable

Useful commands:

```bash
sudo ufw status verbose
systemctl --failed
journalctl -p err -b
ss -tulpn
```

## Recommended Baseline Layout

- `/opt/myapp` application release or compose files
- `/etc/myapp` environment and config files
- `/var/log/myapp` application-specific logs if not fully using journald
- `/srv/` shared data if the host serves static or persistent content

## Best Practices

- Disable root SSH login after confirming key-based access for the admin user.
- Use a named admin account and separate service accounts for apps.
- Keep the host minimal and install only what is required.
- Prefer infrastructure automation for repeatability after validating the manual baseline.
- Use UTC on servers and standardize package and firewall policy across environments.
