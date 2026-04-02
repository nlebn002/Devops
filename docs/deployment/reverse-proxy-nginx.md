# Reverse Proxy With Nginx

This guide explains how to place Nginx in front of an application to handle inbound HTTP and HTTPS traffic, TLS termination, headers, and basic request routing.

## Why Use A Reverse Proxy

Nginx is commonly used to:

- terminate TLS
- route traffic to upstream apps
- serve static files
- add security and forwarding headers
- handle compression and request limits
- centralize access logs

## Basic Flow

Client request:

1. Hits Nginx on port `80` or `443`
2. Nginx validates the request and optional TLS
3. Nginx forwards to an upstream app, for example `127.0.0.1:3000`
4. Nginx returns the upstream response to the client

## Install And Enable

```bash
sudo apt update
sudo apt install -y nginx
sudo systemctl enable --now nginx
```

Validate:

```bash
systemctl status nginx
curl -I http://127.0.0.1
```

## Directory Layout

Common Ubuntu locations:

- `/etc/nginx/nginx.conf`
- `/etc/nginx/sites-available/`
- `/etc/nginx/sites-enabled/`
- `/var/log/nginx/access.log`
- `/var/log/nginx/error.log`

## Basic Reverse Proxy Example

Example server block:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name app.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Place this in:

```bash
/etc/nginx/sites-available/myapp.conf
```

Enable it:

```bash
sudo ln -s /etc/nginx/sites-available/myapp.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Static Files

To serve static assets directly:

```nginx
location /static/ {
    alias /opt/myapp/current/static/;
    access_log off;
    expires 7d;
}
```

This reduces load on the upstream application.

## Timeouts And Body Size

Common settings:

```nginx
client_max_body_size 20m;
proxy_connect_timeout 5s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;
send_timeout 60s;
```

Increase these only when the application actually needs it.

## WebSockets

For WebSocket-based apps, include:

```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

Without these, upgrade requests may fail.

## Security Headers

Typical baseline:

```nginx
add_header X-Content-Type-Options nosniff always;
add_header X-Frame-Options SAMEORIGIN always;
add_header Referrer-Policy strict-origin-when-cross-origin always;
```

Content Security Policy should be set deliberately for the application, not copied blindly from generic examples.

## TLS Termination

Typical HTTPS server:

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name app.example.com;

    ssl_certificate /etc/letsencrypt/live/app.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.example.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

Redirect HTTP to HTTPS:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name app.example.com;
    return 301 https://$host$request_uri;
}
```

## Logging

Default logs:

```bash
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

During debugging:

```bash
sudo nginx -t
journalctl -u nginx -n 100 --no-pager
```

## Upstream Health Checks

Nginx open source does not provide advanced active upstream health checks in the same way as some dedicated load balancers. In many deployments, health checking is handled by:

- external load balancers
- orchestrators such as Kubernetes
- application-level monitoring

## Troubleshooting

### `502 Bad Gateway`

Usually means:

1. upstream app is down
2. upstream port is wrong
3. app is listening on a different interface
4. timeout or crash before response

Check:

```bash
ss -tulpn | grep ':3000'
curl -I http://127.0.0.1:3000
tail -n 100 /var/log/nginx/error.log
```

### `413 Request Entity Too Large`

Increase:

```nginx
client_max_body_size 20m;
```

### Config errors after edit

Always validate before reload:

```bash
sudo nginx -t
```

## Best Practices

- Keep the app bound to localhost or a private interface when Nginx is the public entry point.
- Always test config with `nginx -t` before reload.
- Forward `Host`, client IP, and scheme headers correctly.
- Redirect HTTP to HTTPS once certificates are in place.
- Use explicit, minimal server blocks rather than copying large default configs.
