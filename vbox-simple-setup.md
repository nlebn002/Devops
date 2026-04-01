# Ubuntu VM Setup For This Project - Short HTTPS Version With Real Domain

This guide assumes:

- The VirtualBox VM already exists.
- The VM already uses a `Bridged Adapter`.
- Ubuntu Server `24.04 LTS` will be installed.
- You have a real domain name.
- Your domain points to the VM IP address.
- You want Nginx to serve HTTPS on port `443` with Let's Encrypt.

Example domain used below:

```text
shop.example.com
```

Replace it with your real domain.

---

# Step 1 - Install Ubuntu Server

In the installer:

1. Choose language and keyboard.
2. Keep the detected network.
3. Set hostname, for example:

```text
ecommerce-prod-01
```

4. Create a normal user, for example:

```text
username: nik
```

5. Check `Install OpenSSH server`.
6. Choose `Use an entire disk`.
7. Finish the installation and reboot.

If you need to create an admin user later:

```bash
sudo adduser nik
sudo usermod -aG sudo nik
```

If you forgot OpenSSH:

```bash
sudo apt update
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
```

---

# Step 2 - Update Ubuntu

```bash
sudo apt update
sudo apt full-upgrade -y
sudo timedatectl set-timezone Europe/Prague
sudo reboot
```

---

# Step 3 - Create A VirtualBox Snapshot

In VirtualBox:

1. Shut down the VM.
2. Create a snapshot named:

```text
fresh-ubuntu-24
```

3. Start the VM again.

---

# Step 4 - Install Base Packages

```bash
sudo apt install -y ca-certificates curl git jq unzip vim ufw fail2ban htop ncdu
```

---

# Step 5 - Set Up SSH Keys

On your host machine:

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
ssh-copy-id nik@192.168.x.x
```

On the VM, harden SSH:

```bash
sudo nano /etc/ssh/sshd_config
```

Set:

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
```

Restart SSH:

```bash
sudo systemctl restart ssh
```

---

# Step 6 - Configure Firewall And Fail2ban

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose
sudo systemctl enable --now fail2ban
```

---

# Step 7 - Install Docker

```bash
sudo apt remove -y docker.io docker-doc docker-compose podman-docker containerd runc
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker
docker ps
```

---

# Step 8 - Create App Directories

```bash
sudo mkdir -p /opt/ecommerce
sudo mkdir -p /etc/ecommerce
sudo mkdir -p /var/log/ecommerce
sudo chown -R $USER:$USER /opt/ecommerce /etc/ecommerce /var/log/ecommerce
```

---

# Step 9 - Copy Or Clone The Project

Option A:

```bash
cd /opt
git clone <your-repo-url> ecommerce
cd /opt/ecommerce
```

Option B from your host:

```bash
scp -r /path/to/project nik@192.168.x.x:/opt/ecommerce
```

---

# Step 10 - Create The Environment File

```bash
cd /opt/ecommerce
touch .env
chmod 600 .env
nano .env
```

Example:

```text
POSTGRES_USER=ecommerce
POSTGRES_PASSWORD=change-this
POSTGRES_DB=ecommerce
```

---

# Step 11 - Start The Application

```bash
cd /opt/ecommerce
docker compose -f docker-compose-ephemeral.yml up -d --build
docker compose ps
docker compose logs --tail=200
curl http://localhost:5010/health/ready
```

---

# Step 12 - Install Nginx And Certbot

```bash
sudo apt install -y nginx certbot python3-certbot-nginx
sudo systemctl enable --now nginx
sudo systemctl status nginx
```

Allow Nginx through the firewall:

```bash
sudo ufw allow 'Nginx Full'
sudo ufw status
```

---

# Step 13 - Check The Domain Before Certificates

Your domain must already point to the VM IP address.

From the VM, check the public IP:

```bash
curl ifconfig.me
```

From your host machine, check the domain:

```bash
nslookup shop.example.com
```

The domain should resolve to the VM public IP.

Important:

- Let's Encrypt will not work if the domain does not point to this server.
- Port `80` must be reachable from the internet during certificate creation.

---

# Step 14 - Create A Temporary Nginx Site On Port 80

Create the site config:

```bash
sudo nano /etc/nginx/sites-available/ecommerce
```

Paste:

```nginx
server {
    listen 80;
    server_name shop.example.com;

    location / {
        proxy_pass http://127.0.0.1:5010;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/ecommerce /etc/nginx/sites-enabled/ecommerce
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

Test:

```bash
curl http://localhost
curl http://shop.example.com
```

Replace `shop.example.com` with your real domain.

---

# Step 15 - Create The HTTPS Certificate With Let's Encrypt

Run:

```bash
sudo certbot --nginx -d shop.example.com
```

What Certbot will ask:

1. Your email address
2. Whether you agree to the Let's Encrypt terms
3. Whether you want to share your email with EFF
4. Whether to redirect HTTP to HTTPS

Choose the redirect option when asked.

If you also use `www`, include both names:

```bash
sudo certbot --nginx -d shop.example.com -d www.shop.example.com
```

After success, test:

```bash
sudo nginx -t
sudo systemctl reload nginx
curl https://shop.example.com
```

Open it in the browser:

```text
https://shop.example.com
```

---

# Step 16 - Check Automatic Renewal

Test renewal:

```bash
sudo certbot renew --dry-run
```

Check the renewal timer:

```bash
systemctl status certbot.timer
```

If the timer is active, renewal is configured.

---

# Step 17 - Reboot Test

```bash
sudo reboot
```

After reboot:

```bash
systemctl status docker
systemctl status nginx
docker ps
curl https://shop.example.com
curl http://localhost:5010/health/ready
```

---

# Step 18 - Daily Commands

```bash
docker compose ps
docker compose logs --tail=200
docker ps
df -h
free -h
ss -tulpn
journalctl -xeu docker
journalctl -xeu nginx
journalctl -u certbot
```

---

# Public Ports

Keep public:

- `22`
- `80`
- `443`

Do not expose unless needed:

- `5432`
- `5672`
- `15672`
- `5010`
- `5020`
- `5030`
- `5040`

---

# If Certbot Fails

Check:

1. The domain points to the correct server.
2. Port `80` is open.
3. Nginx is running.
4. The domain is public, not only local LAN DNS.

Useful commands:

```bash
sudo nginx -t
sudo systemctl status nginx
sudo certbot certificates
```
