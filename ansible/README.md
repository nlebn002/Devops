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
- SSH, UFW, fail2ban, openssl, and basic utility packages

Services deployed as containers:
- `nginx` reverse proxy
- your application stack from `/opt/myapp/docker-compose.yml`

## What changed

`nginx` is no longer installed as a host service. It now runs as a Docker container managed by Ansible.

Configuration is stored on the host and mounted into the container:
- nginx compose file: `/opt/nginx/compose.yml`
- nginx vhost config: `/opt/nginx/conf.d/myapp.conf`
- self-signed TLS files: `/opt/nginx/tls`

The reverse proxy forwards traffic to the app on the Docker host using `host.docker.internal`. Your app must publish its HTTP port on the host, typically `127.0.0.1:5000`.
For testing, nginx listens on `80` and `443`, redirects all HTTP traffic to HTTPS, and uses a self-signed certificate generated on the VM.

## Variables

Main variables are in `group_vars/all.yml`.

Important values:
- `deploy_user`
- `app_dir`
- `app_port`
- `nginx_dir`

## Usage

1. Update `inventory/hosts.ini`.
2. Update values in `group_vars/all.yml`.
3. Run the playbook:

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml
```

4. Put your application compose file into `/opt/myapp/docker-compose.yml`.
5. Make sure the app publishes a host port such as `127.0.0.1:5000:80`.
6. Open `http://SERVER_IP` and nginx will redirect you to `https://SERVER_IP`.
7. Accept the browser warning if you want to continue, because the certificate is self-signed.

## Notes

- `nginx` container listens on ports `80` and `443`.
- The current setup is intentionally test-only and does not require a real domain.
- `templates/docker-compose.yml.j2` is only a sample app compose file written to `/opt/myapp/docker-compose.yml` if that file does not exist.
- `templates/nginx-compose.yml.j2` is the separate compose file that runs the nginx reverse proxy in `/opt/nginx/compose.yml`.
