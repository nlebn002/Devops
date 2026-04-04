#!/usr/bin/env bash
set -euo pipefail

### =========================
### Config
### =========================
DEPLOY_USER="${DEPLOY_USER:-deploy}"
DEPLOY_USER_HOME="/home/${DEPLOY_USER}"
APP_DIR="${APP_DIR:-/opt/myapp}"
APP_ENV_FILE="${APP_DIR}/.env.production"

DOMAIN="${DOMAIN:-example.com}"
APP_PORT="${APP_PORT:-5000}"
SSH_PORT="${SSH_PORT:-22}"
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-you@example.com}"
INSTALL_CERT="${INSTALL_CERT:-false}"
RUN_DIST_UPGRADE="${RUN_DIST_UPGRADE:-false}"

SSH_PUBKEY="${SSH_PUBKEY:-}"
SSH_PUBKEY_FILE="${SSH_PUBKEY_FILE:-}"
SSH_PUBKEY_URL="${SSH_PUBKEY_URL:-}"
SSH_GITHUB_USER="${SSH_GITHUB_USER:-}"

### =========================
### Helpers
### =========================
log() {
  echo
  echo "========== $1 =========="
}

fail() {
  echo "ERROR: $1" >&2
  exit 1
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    fail "Run as root."
  fi
}

user_exists() {
  id "$1" >/dev/null 2>&1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

usage() {
  cat <<'EOF'
Usage:
  sudo bash ubuntu-signle-vm.bash [options]

Options:
  --ssh-pubkey <key>         Full public key content.
  --ssh-pubkey-file <path>   Path to a public key file on the server.
  --ssh-pubkey-url <url>     URL that returns the public key.
  --github-user <user>       Download keys from https://github.com/<user>.keys
  --help                     Show this help.

Environment overrides:
  DEPLOY_USER, APP_DIR, DOMAIN, APP_PORT, SSH_PORT,
  LETSENCRYPT_EMAIL, INSTALL_CERT, RUN_DIST_UPGRADE,
  SSH_PUBKEY, SSH_PUBKEY_FILE, SSH_PUBKEY_URL, SSH_GITHUB_USER

Examples:
  sudo SSH_PUBKEY="$(cat ~/.ssh/id_ed25519.pub)" bash ubuntu-signle-vm.bash
  sudo bash ubuntu-signle-vm.bash --ssh-pubkey-file /root/vm.pub
  sudo bash ubuntu-signle-vm.bash --ssh-pubkey-url https://example.com/vm.pub
  sudo bash ubuntu-signle-vm.bash --github-user your-github-login
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ssh-pubkey)
        SSH_PUBKEY="${2:?Missing value for --ssh-pubkey}"
        shift 2
        ;;
      --ssh-pubkey-file)
        SSH_PUBKEY_FILE="${2:?Missing value for --ssh-pubkey-file}"
        shift 2
        ;;
      --ssh-pubkey-url)
        SSH_PUBKEY_URL="${2:?Missing value for --ssh-pubkey-url}"
        shift 2
        ;;
      --github-user)
        SSH_GITHUB_USER="${2:?Missing value for --github-user}"
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        fail "Unknown argument: $1"
        ;;
    esac
  done
}

validate_required_values() {
  [[ "${DOMAIN}" != "example.com" ]] || fail "Set DOMAIN before running."
  [[ "${LETSENCRYPT_EMAIL}" != "you@example.com" ]] || [[ "${INSTALL_CERT}" != "true" ]] || fail "Set LETSENCRYPT_EMAIL before INSTALL_CERT=true."
}

resolve_ssh_pubkey() {
  local resolved_key=""

  if [[ -n "${SSH_PUBKEY}" ]]; then
    resolved_key="${SSH_PUBKEY}"
  elif [[ -n "${SSH_PUBKEY_FILE}" ]]; then
    [[ -f "${SSH_PUBKEY_FILE}" ]] || fail "SSH_PUBKEY_FILE does not exist: ${SSH_PUBKEY_FILE}"
    resolved_key="$(tr -d '\r' < "${SSH_PUBKEY_FILE}")"
  elif [[ -n "${SSH_PUBKEY_URL}" ]]; then
    resolved_key="$(curl -fsSL "${SSH_PUBKEY_URL}" | tr -d '\r')"
  elif [[ -n "${SSH_GITHUB_USER}" ]]; then
    resolved_key="$(curl -fsSL "https://github.com/${SSH_GITHUB_USER}.keys" | head -n 1 | tr -d '\r')"
  fi

  [[ -n "${resolved_key}" ]] || fail "No SSH public key provided. Set SSH_PUBKEY, SSH_PUBKEY_FILE, SSH_PUBKEY_URL, or SSH_GITHUB_USER."

  case "${resolved_key}" in
    ssh-ed25519\ *|ssh-rsa\ *|ecdsa-*\ *|sk-ssh-ed25519@openssh.com\ *|sk-ecdsa-sha2-nistp256@openssh.com\ *)
      SSH_PUBKEY="${resolved_key}"
      ;;
    *)
      fail "Resolved SSH public key does not look valid."
      ;;
  esac
}

append_authorized_key() {
  local key_file="$1"

  touch "${key_file}"
  chmod 600 "${key_file}"
  if ! grep -Fqx "${SSH_PUBKEY}" "${key_file}"; then
    printf '%s\n' "${SSH_PUBKEY}" >> "${key_file}"
  fi
}

write_sshd_dropin() {
  install -d -m 755 /etc/ssh/sshd_config.d

  cat > /etc/ssh/sshd_config.d/99-myapp-hardening.conf <<EOF
Port ${SSH_PORT}
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
X11Forwarding no
PrintMotd no
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers ${DEPLOY_USER}
EOF
}

ensure_ssh_include() {
  local sshd_config="/etc/ssh/sshd_config"
  if ! grep -Eq '^Include /etc/ssh/sshd_config\.d/\*\.conf$' "${sshd_config}"; then
    cp "${sshd_config}" "${sshd_config}.bak.$(date +%s)"
    printf 'Include /etc/ssh/sshd_config.d/*.conf\n%s' "$(cat "${sshd_config}")" > "${sshd_config}"
  fi
}

allow_ufw_rule() {
  local rule="$1"
  if ! ufw status | grep -Fq "${rule}"; then
    ufw allow "${rule}"
  fi
}

### =========================
### Start
### =========================
require_root
parse_args "$@"
validate_required_values
resolve_ssh_pubkey
export DEBIAN_FRONTEND=noninteractive

log "Update package index"
apt-get update
if [[ "${RUN_DIST_UPGRADE}" == "true" ]]; then
  log "Upgrade installed packages"
  apt-get upgrade -y
fi

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
append_authorized_key "${DEPLOY_USER_HOME}/.ssh/authorized_keys"
chown "${DEPLOY_USER}:${DEPLOY_USER}" "${DEPLOY_USER_HOME}/.ssh/authorized_keys"

log "Harden SSH config"
ensure_ssh_include
write_sshd_dropin
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
install -d -m 755 -o "${DEPLOY_USER}" -g "${DEPLOY_USER}" "${APP_DIR}"
touch "${APP_ENV_FILE}"
chown "${DEPLOY_USER}:${DEPLOY_USER}" "${APP_ENV_FILE}"
chmod 600 "${APP_ENV_FILE}"

log "Configure UFW firewall"
ufw default deny incoming
ufw default allow outgoing
allow_ufw_rule "${SSH_PORT}/tcp"
allow_ufw_rule "80/tcp"
allow_ufw_rule "443/tcp"
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
echo "1. Verify you can open a second SSH session as ${DEPLOY_USER} before closing the current one"
echo "2. Put your app/docker-compose into ${APP_DIR}"
echo "3. Make sure your app binds to 127.0.0.1:${APP_PORT} or container publishes 127.0.0.1:${APP_PORT}"
echo "4. Point DNS for ${DOMAIN} to this server"
echo "5. If DNS is ready, rerun with INSTALL_CERT=true or run certbot manually"
echo
echo "Checks:"
echo "  ssh -p ${SSH_PORT} ${DEPLOY_USER}@<server-ip>"
echo "  docker --version"
echo "  docker compose version"
echo "  nginx -t"
echo "  ufw status verbose"
echo "  fail2ban-client status sshd"
echo "  ss -tuln | grep -E ':80|:443|:${SSH_PORT}'"
echo
echo "Public key sources supported:"
echo "  SSH_PUBKEY, SSH_PUBKEY_FILE, SSH_PUBKEY_URL, SSH_GITHUB_USER"
