# SSL With Certbot

This guide covers obtaining and renewing TLS certificates with Let's Encrypt using Certbot, typically for Nginx on Ubuntu.

## Goals

- issue a trusted certificate
- enable HTTPS
- automate renewal
- avoid downtime during renewal

## Prerequisites

- a public DNS record points to the server
- ports `80` and `443` are reachable
- Nginx is installed and serving the target hostname
- the server clock is correct

Confirm DNS:

```bash
dig +short app.example.com
```

Confirm inbound reachability:

```bash
curl -I http://app.example.com
```

## Install Certbot

For Ubuntu with Nginx:

```bash
sudo apt update
sudo apt install -y certbot python3-certbot-nginx
```

## Request A Certificate

Automatic Nginx integration:

```bash
sudo certbot --nginx -d app.example.com
```

For multiple names:

```bash
sudo certbot --nginx -d example.com -d www.example.com
```

Certbot can update Nginx configuration automatically when using the Nginx plugin.

## Test And Verify

After issuance:

```bash
sudo nginx -t
sudo systemctl reload nginx
curl -I https://app.example.com
openssl s_client -connect app.example.com:443 -servername app.example.com </dev/null
```

Certificate files are typically stored under:

```bash
/etc/letsencrypt/live/app.example.com/
```

## Renewal

Let's Encrypt certificates are short-lived and should be renewed automatically.

Check the renewal timer:

```bash
systemctl list-timers | grep certbot
```

Test renewal:

```bash
sudo certbot renew --dry-run
```

If renewal succeeds in dry-run mode, the automation path is usually healthy.

## HTTP To HTTPS Redirect

Use a dedicated redirect server block:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name app.example.com;
    return 301 https://$host$request_uri;
}
```

Do not redirect before initial issuance if you are relying on the HTTP challenge path and your current Nginx setup is not yet valid.

## Firewall Rules

Allow inbound web traffic:

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## Common Failure Causes

### DNS is wrong

Symptoms:

- challenge fails
- Certbot cannot validate the domain

Check:

```bash
dig +short app.example.com
```

### Port `80` is blocked

HTTP validation often needs inbound port `80`, even if the final site should serve only HTTPS.

Check:

```bash
ss -tulpn | grep ':80'
sudo ufw status
```

### Nginx config is invalid

Check:

```bash
sudo nginx -t
```

### Another process owns port `80` or `443`

Check:

```bash
sudo ss -tulpn | grep -E ':80|:443'
```

## Wildcard Certificates

Wildcard certificates such as `*.example.com` require DNS-based validation rather than the basic HTTP challenge flow.

That usually means:

- DNS provider API integration
- manual DNS TXT record creation
- more operational complexity

Use wildcard certs only when they solve a real need across many subdomains.

## Security Notes

- Private keys under `/etc/letsencrypt/` should remain readable only by privileged users.
- Keep the OS clock synchronized or issuance and renewal can fail unpredictably.
- Use modern TLS defaults from current Nginx and Certbot packages rather than hand-writing obsolete cipher lists from old blog posts.

## Best Practices

- Automate renewal and test it with `certbot renew --dry-run`.
- Use the Nginx plugin when your deployment is straightforward and you want less manual config work.
- Validate DNS, firewall, and Nginx before requesting certificates.
- Redirect HTTP to HTTPS after certificate issuance is confirmed.
- Monitor certificate expiry as part of your alerting stack.
