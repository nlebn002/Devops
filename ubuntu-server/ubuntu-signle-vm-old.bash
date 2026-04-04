#!/usr/bin/env bash
set -euo pipefail

### =========================
### Config
### =========================
DEPLOY_USER="deploy"
DEPLOY_USER_HOME="/home/${DEPLOY_USER}"
APP_DIR="/opt/myapp"
APP_ENV_FILE="${APP_DIR}/.env.production"

DOMAIN="example.com"          # change
APP_PORT="5000"               # app listens only internally
SSH_PORT="22"                 # change if you want
LETSENCRYPT_EMAIL="you@example.com"   # change
INSTALL_CERT="false"          # set true only after DNS points to this server

# Paste your LOCAL public key here
SSH_PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4Ibzb5HjhQUgGshGNeYZ0+VeO6sIgen6CuPuKBcDGK vbox@vbox"

### =========================
### Helpers
### =========================
log() {
  echo
  echo "========== $1 =========="
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run as root."
    exit 1
  fi
}

user_exists() {
  id "$1" >/dev/null 2>&1
}

### =========================
### Start
### =========================
require_root
export DEBIAN_FRONTEND=noninteractive

log "Update system"
apt-get update
apt-get upgrade -y

log "Install base packages"
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  ufw \
  nginx \
  git \
  unzip \
  openssh-server \
  sudo \
  fail2ban \
  certbot \
  python3-certbot-nginx \
  apt-transport-https \
  software-properties-common

log "Ensure SSH service is enabled"
systemctl enable ssh
systemctl restart ssh

log "Create deploy user"
if ! user_exists "${DEPLOY_USER}"; then
  adduser --disabled-password --gecos "" "${DEPLOY_USER}"
fi

log "Add deploy user to sudo"
usermod -aG sudo "${DEPLOY_USER}"

log "Prepare SSH for deploy user"
install -d -m 700 -o "${DEPLOY_USER}" -g "${DEPLOY_USER}" "${DEPLOY_USER_HOME}/.ssh"

# if [[ -z "${SSH_PUBKEY}" || "${SSH_PUBKEY}" == *"REPLACE_ME"* ]]; then
#   echo "ERROR: Set SSH_PUBKEY before running."
#   exit 1
# fi

echo "${SSH_PUBKEY}" > "${DEPLOY_USER_HOME}/.ssh/authorized_keys"
chown "${DEPLOY_USER}:${DEPLOY_USER}" "${DEPLOY_USER_HOME}/.ssh/authorized_keys"
chmod 600 "${DEPLOY_USER_HOME}/.ssh/authorized_keys"

log "Harden SSH config"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%s)

cat > /etc/ssh/sshd_config <<EOF
Port ${SSH_PORT}
Protocol 2
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
PubkeyAuthentication yes
X11Forwarding no
PrintMotd no
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers ${DEPLOY_USER}
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

sshd -t
systemctl restart ssh

log "Install Docker"
install -m 0755 -d /etc/apt/keyrings

if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
fi

ARCH="$(dpkg --print-architecture)"
UBUNTU_CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"

cat > /etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable
EOF

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl enable containerd
systemctl restart docker

log "Add deploy user to docker group"
usermod -aG docker "${DEPLOY_USER}"

log "Prepare app directory"
mkdir -p "${APP_DIR}"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${APP_DIR}"
chmod 755 "${APP_DIR}"

touch "${APP_ENV_FILE}"
chown "${DEPLOY_USER}:${DEPLOY_USER}" "${APP_ENV_FILE}"
chmod 600 "${APP_ENV_FILE}"

log "Configure UFW firewall"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow "${SSH_PORT}/tcp"
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

log "Configure fail2ban"
cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = ${SSH_PORT}
logpath = %(sshd_log)s
backend = systemd
maxretry = 5
findtime = 10m
bantime = 1h
EOF

systemctl enable fail2ban
systemctl restart fail2ban

log "Configure Nginx reverse proxy"
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default

cat > /etc/nginx/sites-available/myapp <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};

    access_log /var/log/nginx/myapp_access.log;
    error_log /var/log/nginx/myapp_error.log;

    client_max_body_size 20M;

    location / {
        proxy_pass http://127.0.0.1:${APP_PORT};
        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

ln -sf /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/myapp
nginx -t
systemctl enable nginx
systemctl restart nginx

log "Optional HTTPS install"
if [[ "${INSTALL_CERT}" == "true" ]]; then
  certbot --nginx --non-interactive --agree-tos -m "${LETSENCRYPT_EMAIL}" -d "${DOMAIN}" --redirect
fi

log "Create sample docker compose if missing"
if [[ ! -f "${APP_DIR}/docker-compose.yml" ]]; then
  cat > "${APP_DIR}/docker-compose.yml" <<'EOF'
services:
  app:
    image: nginx:alpine
    container_name: myapp
    restart: unless-stopped
    ports:
      - "127.0.0.1:5000:80"
EOF
  chown "${DEPLOY_USER}:${DEPLOY_USER}" "${APP_DIR}/docker-compose.yml"
fi

log "Done"
echo "Deploy user: ${DEPLOY_USER}"
echo "App dir: ${APP_DIR}"
echo "App env file: ${APP_ENV_FILE}"
echo "Domain: ${DOMAIN}"
echo
echo "Next steps:"
echo "1. Log in as ${DEPLOY_USER}"
echo "2. Put your app/docker-compose into ${APP_DIR}"
echo "3. Make sure your app binds to 127.0.0.1:${APP_PORT} or container publishes 127.0.0.1:${APP_PORT}"
echo "4. Point DNS for ${DOMAIN} to this server"
echo "5. Set INSTALL_CERT=true and run certbot step, or run manually:"
echo "   certbot --nginx --non-interactive --agree-tos -m ${LETSENCRYPT_EMAIL} -d ${DOMAIN} --redirect"
echo
echo "Checks:"
echo "  ssh -p ${SSH_PORT} ${DEPLOY_USER}@<server-ip>"
echo "  docker --version"
echo "  docker compose version"
echo "  nginx -t"
echo "  ufw status verbose"
echo "  fail2ban-client status sshd"
echo "  ss -tuln | grep -E ':80|:443|:${SSH_PORT}'"