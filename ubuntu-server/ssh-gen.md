# SSH Key Generation and Server Setup

This is a short manual for creating an SSH key on your working machine and configuring an Ubuntu server for secure key-based login.

## 1. Generate SSH key on the working machine

Run on your local machine:

```bash
ssh-keygen -t ed25519 -C "deploy@your-machine"
```

When asked for file location, you can keep the default:

```bash
~/.ssh/id_ed25519
```

This creates:

- `~/.ssh/id_ed25519`: private key, keep it secret
- `~/.ssh/id_ed25519.pub`: public key, copy to servers

Show the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

## 2. Copy the public key to the Ubuntu server

Recommended method:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server-ip
```

If `ssh-copy-id` is not available, copy it manually:

```bash
cat ~/.ssh/id_ed25519.pub
ssh user@server-ip
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
```

Paste the public key into `~/.ssh/authorized_keys`, then run:

```bash
chmod 600 ~/.ssh/authorized_keys
```

## 3. Test login

From the working machine:

```bash
ssh -i ~/.ssh/id_ed25519 user@server-ip
```

If this works without using a password, key authentication is ready.

## 4. Configure the server correctly

Open SSH server config:

```bash
sudo nano /etc/ssh/sshd_config
```

Set or confirm these values:

```text
PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
```

Optional: change SSH port from `22` to a custom port:

```text
Port 22
```

If you change the port, update firewall rules and all deployment scripts.

## 5. Restart SSH service

After saving `sshd_config`:

```bash
sudo sshd -t
sudo systemctl restart ssh
```

`sshd -t` checks config syntax before restart.

## 6. Configure firewall

If UFW is enabled, allow SSH:

```bash
sudo ufw allow 22/tcp
sudo ufw enable
sudo ufw status
```

If you changed the SSH port, allow that port instead of `22`.

## 7. Save values for automation

For GitHub Actions or other deployment automation you usually need:

- `SSH_HOST`: server IP or DNS name
- `SSH_PORT`: SSH port, usually `22`
- `SSH_USER`: deploy user on Ubuntu
- `SSH_PRIVATE_KEY`: content of `~/.ssh/id_ed25519`
- `SSH_KNOWN_HOSTS`: output of:

```bash
ssh-keyscan -p 22 server-ip
```

If you use another port, replace `22` with the real one.

## 8. Important rules

- Never copy the private key to the server.
- Only the public key goes into `authorized_keys`.
- Always test a second SSH session before closing the first one after changing `sshd_config`.
- Use a dedicated deploy user instead of `root`.
