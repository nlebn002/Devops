# Common Linux Commands

This page covers the commands used most often when operating Linux servers. Examples assume a Bourne-compatible shell such as `bash`.

## Navigation And Inspection

### Print the current directory

```bash
pwd
```

### List files

```bash
ls -lah
ls -lah /var/log
```

Use:

- `-l` for long format
- `-a` to include hidden files
- `-h` for human-readable sizes

### Change directories

```bash
cd /etc
cd ..
cd ~
```

### Show file type

```bash
file /bin/bash
```

## Reading Files

### Print a file

```bash
cat /etc/os-release
```

Good for small files only.

### Page through large files

```bash
less /var/log/syslog
less /var/log/messages
```

Useful keys:

- `/text` to search
- `n` for next result
- `q` to quit

### Show the beginning or end of a file

```bash
head -n 20 /var/log/nginx/access.log
tail -n 50 /var/log/nginx/error.log
tail -f /var/log/nginx/access.log
```

`tail -f` is standard for watching logs in real time.

## Searching

### Search for files

```bash
find /etc -name "*.conf"
find /var/log -type f -mtime -1
```

Use `find` carefully on large trees because it can be expensive.

### Search inside files

```bash
grep -Rni "listen 80" /etc/nginx
grep -Rni --color "error" /var/log
```

Useful flags:

- `-R` recursive
- `-n` line numbers
- `-i` case-insensitive

If available, `rg` is faster and usually easier to use:

```bash
rg -n "server_name" /etc/nginx
```

## File And Directory Operations

### Copy, move, and remove

```bash
cp source.txt backup.txt
cp -r app/ app.bak/
mv old.conf new.conf
rm file.txt
rm -r old-directory/
```

Use `rm -r` with care. Prefer checking paths with `pwd` and `ls` first.

### Create files and directories

```bash
touch app.log
mkdir releases
mkdir -p /opt/myapp/shared/config
```

## Permissions And Ownership

### Change ownership

```bash
sudo chown -R appuser:appgroup /opt/myapp
```

### Change permissions

```bash
chmod 644 config.yml
chmod 755 deploy.sh
chmod -R u=rwX,g=rX,o= /opt/myapp
```

For application directories, symbolic modes are often clearer and safer than raw octal values.

## Process And System Commands

### Show running processes

```bash
ps aux
ps aux | grep nginx
```

### Interactive process viewers

```bash
top
htop
```

`htop` is easier to read if installed.

### Check memory and uptime

```bash
free -h
uptime
```

### Check disk usage

```bash
df -h
du -sh /var/log
du -sh ./*
```

`df` shows filesystem usage. `du` shows directory and file usage.

## Archives And Compression

### Create and extract tar archives

```bash
tar -czf backup.tar.gz /etc/myapp
tar -xzf backup.tar.gz
```

### Work with zip files

```bash
zip -r release.zip app/
unzip release.zip
```

## Networking Basics

### Test connectivity

```bash
ping -c 4 8.8.8.8
curl -I https://example.com
wget https://example.com/file.tar.gz
```

### Show listening ports

```bash
ss -tulpn
sudo ss -tulpn | grep 443
```

Prefer `ss` over the older `netstat`.

## Package Management

### Debian and Ubuntu

```bash
sudo apt update
sudo apt upgrade
sudo apt install nginx
```

### RHEL, Rocky, AlmaLinux, Fedora

```bash
sudo dnf check-update
sudo dnf upgrade
sudo dnf install nginx
```

## Service And Log Access

```bash
systemctl status nginx
sudo systemctl restart nginx
journalctl -u nginx -n 100 --no-pager
```

Use `journalctl` instead of searching blindly through `/var/log` when a service is managed by `systemd`.

## Environment And Shell Utilities

### Show environment variables

```bash
env
printenv PATH
echo "$HOME"
```

### Command history

```bash
history
history | tail
```

### Redirect output

```bash
command > output.log
command >> output.log
command 2> error.log
command > all.log 2>&1
```

## Best Practices

- Use `sudo` for privileged operations instead of logging in as `root` directly.
- Prefer `less`, `tail`, `grep`, and `journalctl` over opening large logs in an editor.
- Verify the current directory before running destructive commands.
- Quote paths that may contain spaces: `cat "/path/with spaces/file.txt"`.
- Use shell history carefully on shared systems because commands may expose secrets.
