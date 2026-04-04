# How to run

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml -K 
```
-K means --ask-become-pass.


# Ansible VM bootstrap

This playbook prepares an Ubuntu server for a Docker-based deployment model.

Host-level software installed by Ansible:
- Docker Engine
- Docker Compose plugin
- SSH, UFW, fail2ban, certbot, and basic utility packages

Services deployed as containers:
- `nginx` reverse proxy
- your application stack from `/opt/myapp/docker-compose.yml`

## What changed

`nginx` is no longer installed as a host service. It now runs as a Docker container managed by Ansible.

Configuration is stored on the host and mounted into the container:
- nginx compose file: `/opt/nginx/compose.yml`
- nginx vhost config: `/opt/nginx/conf.d/myapp.conf`
- ACME webroot: `/opt/nginx/www/certbot`
- LetsEncrypt data: `/opt/nginx/certbot`

The reverse proxy forwards traffic to the app on the Docker host using `host.docker.internal`. Your app must publish its HTTP port on the host, typically `127.0.0.1:5000`.

## Variables

Main variables are in `group_vars/all.yml`.

Important values:
- `deploy_user`
- `app_dir`
- `app_port`
- `domain`
- `nginx_dir`
- `letsencrypt_email`
- `install_cert`

## Usage

1. Update `inventory/hosts.ini`.
2. Update values in `group_vars/all.yml`.
3. Run the playbook:

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml
```

4. Put your application compose file into `/opt/myapp/docker-compose.yml`.
5. Make sure the app publishes a host port such as `127.0.0.1:5000:80`.
6. Point DNS for your domain to the server.
7. Set `install_cert: true` and rerun the playbook to request a LetsEncrypt certificate.

## Notes

- `nginx` container listens on ports `80` and `443`.
- TLS certificates are requested with certbot `webroot` mode, not the old `--nginx` integration.
- If `install_cert` is `false`, nginx serves plain HTTP only.
