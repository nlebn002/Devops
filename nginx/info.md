# nginx.production.full.conf

Short explanation of the properties used in this config.

## Global

- `user nginx`: runs nginx worker processes as the `nginx` user.
- `worker_processes auto`: uses a worker count based on available CPU cores.
- `error_log /var/log/nginx/error.log warn`: writes errors and warnings to the nginx error log.
- `pid /var/run/nginx.pid`: stores the master process PID in this file.

## events

- `worker_connections 4096`: maximum simultaneous connections per worker.
- `multi_accept on`: allows a worker to accept multiple new connections at once.
- `use epoll`: uses the Linux `epoll` event method for better performance.

## http

- `include /etc/nginx/mime.types`: loads MIME type mappings.
- `default_type application/octet-stream`: fallback content type for unknown file types.
- `log_format main ...`: defines the `main` access log format.
- `access_log /var/log/nginx/access.log main`: enables access logging with the `main` format.
- `sendfile on`: sends files more efficiently from disk to network.
- `tcp_nopush on`: optimizes packet sending for larger responses.
- `tcp_nodelay on`: sends small packets immediately for lower latency.
- `keepalive_timeout 65`: keeps client connections open for 65 seconds.
- `keepalive_requests 1000`: allows up to 1000 requests on one keepalive connection.
- `server_tokens off`: hides the nginx version in responses.
- `types_hash_max_size 4096`: increases hash table size for MIME types.
- `client_max_body_size 20m`: limits request body size to 20 MB.

## gzip

- `gzip on`: enables response compression.
- `gzip_comp_level 5`: sets a balanced compression level.
- `gzip_min_length 1024`: compresses only responses larger than 1 KB.
- `gzip_proxied any`: allows compression for proxied requests.
- `gzip_vary on`: adds the `Vary: Accept-Encoding` header.
- `gzip_types ...`: lists content types that should be compressed.

## upstream

- `upstream app_backend`: defines a reusable backend group.
- `server 127.0.0.1:5000`: backend application runs locally on port `5000`.
- `keepalive 32`: keeps up to 32 idle upstream connections open.

## HTTP server

- `listen 80` and `listen [::]:80`: accepts IPv4 and IPv6 HTTP traffic on port `80`.
- `server_name _`: catch-all server name.
- `return 301 https://$host$request_uri`: redirects all HTTP traffic to HTTPS.

## HTTPS server

- `listen 443 ssl http2` and `listen [::]:443 ssl http2`: accepts HTTPS traffic on port `443` with HTTP/2.
- `server_name _`: catch-all HTTPS server.
- `ssl_certificate /etc/nginx/ssl/fullchain.pem`: path to the public certificate chain.
- `ssl_certificate_key /etc/nginx/ssl/privkey.pem`: path to the private key.
- `ssl_session_timeout 1d`: keeps SSL sessions valid for one day.
- `ssl_session_cache shared:SSL:20m`: stores SSL sessions in shared memory.
- `ssl_session_tickets off`: disables session tickets for better security control.
- `ssl_protocols TLSv1.2 TLSv1.3`: allows only modern TLS versions.
- `ssl_prefer_server_ciphers off`: lets modern clients choose ciphers when appropriate.

## Security headers

- `Strict-Transport-Security`: forces browsers to prefer HTTPS for one year.
- `X-Content-Type-Options nosniff`: prevents MIME type sniffing.
- `X-Frame-Options SAMEORIGIN`: allows framing only from the same origin.
- `Referrer-Policy strict-origin-when-cross-origin`: limits referrer data sent to other sites.

## Proxy location

- `location /`: handles all incoming requests.
- `proxy_pass http://app_backend`: forwards requests to the backend upstream.
- `proxy_http_version 1.1`: uses HTTP/1.1 to the backend.
- `proxy_set_header Host $host`: passes the original host header.
- `proxy_set_header X-Real-IP $remote_addr`: passes the client IP.
- `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for`: appends the client IP to the forwarding chain.
- `proxy_set_header X-Forwarded-Proto $scheme`: tells the backend whether the original request used HTTP or HTTPS.
- `proxy_set_header X-Forwarded-Host $host`: passes the original host value.
- `proxy_set_header X-Forwarded-Port $server_port`: passes the original port.
- `proxy_set_header Upgrade $http_upgrade`: supports WebSocket and protocol upgrades.
- `proxy_set_header Connection $connection_upgrade`: sets the correct connection mode for upgrade requests.
- `proxy_connect_timeout 10s`: timeout for connecting to the backend.
- `proxy_send_timeout 60s`: timeout for sending request data to the backend.
- `proxy_read_timeout 60s`: timeout for reading the backend response.
- `send_timeout 60s`: timeout for sending the response to the client.

## map

- `map $http_upgrade $connection_upgrade`: creates a helper variable for upgrade handling.
- `default upgrade`: uses `upgrade` when the client requests a protocol upgrade.
- `'' close`: uses `close` when there is no upgrade request.
