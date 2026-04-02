# Users And Permissions

This guide explains Linux users, groups, ownership, and permission management for server administration.

## Core Concepts

- Every process runs as a user.
- Files and directories have an owner and a group.
- Permissions control read, write, and execute access.
- `root` bypasses most permission checks and should be used sparingly.

## Users And Groups

### Show the current user

```bash
whoami
id
```

### List user account information

```bash
getent passwd
getent passwd deploy
```

### List group information

```bash
getent group
getent group sudo
```

### Create a user

```bash
sudo useradd -m -s /bin/bash deploy
sudo passwd deploy
```

On Debian and Ubuntu, `adduser` is a more interactive wrapper:

```bash
sudo adduser deploy
```

### Modify group membership

```bash
sudo usermod -aG sudo deploy
sudo usermod -aG docker deploy
```

Use `-aG` when adding supplementary groups. Omitting `-a` can remove existing memberships.

## Ownership

### Show file ownership

```bash
ls -l /opt/myapp
```

### Change owner and group

```bash
sudo chown deploy:deploy /opt/myapp/config.yml
sudo chown -R deploy:deploy /opt/myapp
```

## Permissions

Permissions are expressed as:

- `r` read
- `w` write
- `x` execute

They apply separately to:

- User
- Group
- Others

### View permissions

```bash
ls -l deploy.sh
stat deploy.sh
```

### Set permissions with octal modes

```bash
chmod 644 file.txt
chmod 755 deploy.sh
chmod 600 .env
```

Common values:

- `644` owner read/write, group read, others read
- `755` owner read/write/execute, group read/execute, others read/execute
- `600` owner read/write only

### Set permissions with symbolic modes

```bash
chmod u+x deploy.sh
chmod go-rwx secrets.txt
chmod -R u=rwX,g=rX,o= /opt/myapp
```

Symbolic modes are often clearer when hardening directories or making incremental changes.

## Directory Permissions

For directories:

- `r` allows listing names
- `w` allows creating, deleting, or renaming entries
- `x` allows entering the directory and accessing items within it

A directory usually needs `x` to be usable.

## `sudo`

### Run a command with elevated privileges

```bash
sudo systemctl restart nginx
```

### Open a root shell only when necessary

```bash
sudo -i
```

Prefer command-by-command `sudo` usage over long interactive root sessions.

## Special Permission Bits

### Setuid

Runs a binary with the file owner's privileges.

```bash
chmod u+s /path/to/binary
```

### Setgid

On directories, new files inherit the directory group.

```bash
chmod g+s /srv/shared
```

### Sticky bit

Common on shared writable directories such as `/tmp`.

```bash
chmod +t /srv/shared-temp
```

## Access Control Lists

ACLs provide more granular permissions than standard user/group/other modes.

### View ACLs

```bash
getfacl /srv/shared
```

### Set ACLs

```bash
sudo setfacl -m u:deploy:rwx /srv/shared
sudo setfacl -R -m g:ops:rX /srv/shared
```

Use ACLs sparingly. Traditional ownership and group design is easier to audit.

## SSH Access Basics

### Use key-based authentication

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### Prefer disabling password auth on hardened servers

Review `/etc/ssh/sshd_config` settings such as:

- `PasswordAuthentication no`
- `PermitRootLogin no`
- `PubkeyAuthentication yes`

Reload after validation:

```bash
sudo sshd -t
sudo systemctl reload sshd
```

On some systems the service name is `ssh` instead of `sshd`.

## Common Checks

### Why can a user not write here

Check:

1. Owner and group: `ls -ld /path`
2. User memberships: `id username`
3. ACLs: `getfacl /path`
4. Parent directory execute permission

### Why does a script not run

Check:

1. Execute bit: `ls -l script.sh`
2. Shebang, for example `#!/usr/bin/env bash`
3. Line endings if the file was edited on Windows

## Best Practices

- Use named non-root service accounts for applications.
- Grant the smallest permission set that still allows the task to work.
- Prefer groups over broad world-writable permissions.
- Avoid `chmod 777` except for short-lived troubleshooting in isolated environments, and revert it immediately.
- Protect secrets with strict ownership and modes such as `600`.
- Review `sudo` and SSH access regularly on shared systems.
