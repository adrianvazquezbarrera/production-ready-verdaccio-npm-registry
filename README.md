# Production-Ready Verdaccio NPM Registry

A self-hosted private npm registry powered by [Verdaccio](https://verdaccio.org/) with [Traefik](https://traefik.io/) reverse proxy, containerized with Docker for production deployment.

## 📋 Overview

This project provides a production-ready Verdaccio npm registry setup with:

- **Traefik Reverse Proxy** for HTTP/HTTPS traffic management
- **Traefik Basic Authentication** protecting NPM API routes (authentication fully delegated to proxy)
- **Persistent storage** for packages and configuration
- **CI/CD integration** scripts for automated workflows
- **Easy HTTPS setup** with Let's Encrypt (optional)
- **Separated access**: Public UI panel and protected NPM API endpoints

## 🏗️ Architecture

The setup consists of two main services:

1. **Traefik**: Reverse proxy handling incoming requests

   - Routes traffic based on domain and HTTP methods
   - Protects write operations (PUT, DELETE, POST, PATCH) with Basic Authentication
   - Allows public access to read operations (GET) and the web UI
   - Optional HTTPS with automatic Let's Encrypt certificates

2. **Verdaccio**: NPM registry server
   - Handles package storage and serving
   - No authentication (delegated to Traefik)
   - Proxies to npmjs.org for public packages

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose installed
- A domain name (for production deployment)
- Node.js and npm (for package publishing)

### Initial Setup

1. **Configure domain and users**:

   Edit `compose.yml` and replace `localhost` with your actual domain:

   ```yaml
   - "traefik.http.routers.verdaccio-api.rule=Host(`registry.example.com`) && Method(`PUT`) || Method(`DELETE`) || Method(`POST`) || Method(`PATCH`)"
   - "traefik.http.routers.verdaccio-panel.rule=Host(`registry.example.com`)"
   ```

2. **Create htpasswd file for Traefik authentication**:

   ```bash
   # Generate htpasswd file
   htpasswd -nbB username password > traefik/htpasswd

   # Or use Docker (if htpasswd is not installed)
   docker run --rm -it httpd:alpine htpasswd -nbB username password > traefik/htpasswd
   ```

   Replace `username` and `password` with your desired credentials.

3. **Set proper permissions**:

   ```bash
   chmod 600 traefik/htpasswd
   chmod 600 traefik/acme.json  # For HTTPS (if using)
   ```

### Start the Registry

```bash
# Start services
docker compose up -d --build

# Check logs
docker compose logs -f
```

The registry will be available at:

- **Web UI & Read Operations**: `http://localhost` (publicly accessible)
- **Write Operations**: `http://localhost` (PUT/DELETE/POST/PATCH methods protected by Traefik Basic Auth)

### Verify Installation

```bash
# Check if services are running
docker compose ps

# Test the web UI (should be accessible)
curl http://localhost/

# Test authentication with test script
NPM_USER=username NPM_PASS=password ./test-registry.sh
```

**Note I**: Replace `localhost` with your actual domain if not using localhost.

**Note II**: Replace `username` and `password` with the credentials you set in the `htpasswd` file.

## 🔐 Authentication

Authentication is **completely handled by Traefik** using HTTP Basic Auth:

- **Write operations** (PUT, DELETE, POST, PATCH): Protected by Traefik Basic Auth
- **Read operations** (GET) and Web UI: Publicly accessible
- **Verdaccio**: No internal authentication - all auth is delegated to the proxy

### Important Notes

- Users are managed in `traefik/htpasswd` file only
- The same credentials are used for all NPM operations (publish, install, etc.)
- No need to create users in Verdaccio - it trusts requests from Traefik
- First time setup requires using the credentials from `traefik/htpasswd`

### Testing the Registry

Use the provided `test-registry.sh` script to verify the setup:

```bash
# Test with credentials
NPM_USER=myuser NPM_PASS=mypassword ./test-registry.sh

# With custom registry URL
NPM_USER=myuser NPM_PASS=mypassword NPM_REGISTRY_URL=http://registry.example.com/ NPM_REGISTRY=registry.example.com ./test-registry.sh
```

The script:

- Tests that publishing fails without credentials
- Creates a test package and publishes it with credentials
- Verifies the package can be viewed and installed
- Cleans up test artifacts automatically

### GitHub Actions Example

```yaml
- name: Configure npm registry authentication
  run: |
    AUTH=$(echo -n "${{ secrets.NPM_USER }}:${{ secrets.NPM_PASS }}" | base64)
    cat > .npmrc << EOF
    registry=http://registry.example.com/
    //registry.example.com/:_auth=$AUTH
    EOF

- name: Publish package
  run: npm publish --registry=http://registry.example.com/
```

## 📦 Usage

### Publishing Packages

```bash
# Set registry for current project
npm config set registry http://YOUR_DOMAIN_HERE.COM

# Or publish directly to the registry
npm publish --registry http://YOUR_DOMAIN_HERE.COM
```

### Installing Packages

```bash
# Install from private registry
npm install my-package --registry http://YOUR_DOMAIN_HERE.COM

# Or configure registry in .npmrc
echo "registry=http://YOUR_DOMAIN_HERE.COM/" > .npmrc
npm install my-package
```

### Scoped Packages

For organization-scoped packages:

```bash
# Configure scope to use your registry
npm config set @myorg:registry http://YOUR_DOMAIN_HERE.COM

# Install scoped package
npm install @myorg/my-package
```

## ⚙️ Configuration

### Traefik Configuration

Edit the `compose.yml` file to configure Traefik:

#### Enable HTTPS with Let's Encrypt

Uncomment the HTTPS-related lines in `compose.yml`:

```yaml
services:
  traefik:
    command:
      # Uncomment these lines:
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
      - "--certificatesresolvers.myresolver.acme.email=you@example.com"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
    volumes:
      # Uncomment this line:
      - ./traefik/acme.json:/letsencrypt/acme.json

  verdaccio:
    labels:
      # Uncomment these lines:
      - "traefik.http.routers.verdaccio-api.tls.certresolver=myresolver"
      - "traefik.http.routers.verdaccio-panel.tls.certresolver=myresolver"
      - "traefik.http.routers.verdaccio-api.entrypoints=websecure"
      - "traefik.http.routers.verdaccio-panel.entrypoints=websecure"
      # Comment these lines:
      # - "traefik.http.routers.verdaccio-panel.entrypoints=web"
      # - "traefik.http.routers.verdaccio-api.entrypoints=web"
```

Then restart:

```bash
docker compose down
docker compose up -d
```

#### Update htpasswd Users

To add or modify Traefik Basic Auth users:

```bash
# Add a new user
docker run --rm -it httpd:alpine htpasswd -nb newuser newpassword >> traefik/htpasswd

# Replace all users
docker run --rm -it httpd:alpine htpasswd -nb user1 pass1 > traefik/htpasswd
docker run --rm -it httpd:alpine htpasswd -nb user2 pass2 >> traefik/htpasswd

# Restart Traefik
docker compose restart traefik
```

### Verdaccio Configuration

The main configuration file is at `verdaccio/verdaccio-conf/config.yaml`:

```yaml
listen: 0.0.0.0:4873
storage: /verdaccio/storage
plugins: /verdaccio/plugins

web:
  enable: true
  title: Verdaccio

uplinks:
  npmjs:
    url: https://registry.npmjs.org/

packages:
  "@*/*":
    access: $all
    publish: $all
    proxy: npmjs
  "**":
    access: $all
    publish: $all
    proxy: npmjs

middlewares:
  audit:
    enabled: true

log:
  - { type: stdout, format: pretty, level: http }
```

Key settings:

- **Authentication**: Not configured - authentication is handled entirely by Traefik proxy
- **Access Control**: All packages set to `$all` because actual auth is delegated to Traefik
- **Uplinks**: Proxies to npmjs.org for public packages
- **Audit**: Enabled for security logging

After changes, restart Verdaccio:

```bash
docker compose restart verdaccio
```

### Storage

Packages are stored persistently in:

```
./verdaccio/verdaccio-storage/
```

This directory is mounted as a volume and persists between container restarts.

## 🏗️ Project Structure

```
.
├── compose.yml                           # Docker Compose orchestration
├── test-registry.sh                      # Registry testing script
├── README.md                             # This file
├── traefik/
│   ├── acme.json                         # Let's Encrypt certificates (HTTPS)
│   └── htpasswd                          # Basic Auth credentials
└── verdaccio/
    ├── Dockerfile                        # Verdaccio container image
    ├── entrypoint.sh                     # Container startup script
    ├── verdaccio-conf/
    │   └── config.yaml                   # Verdaccio configuration
    └── verdaccio-storage/                # Package storage (persistent)
```

## 🔧 Advanced Usage

### Custom Package Access Rules

**Note**: Since authentication is handled by Traefik based on HTTP methods, Verdaccio's access control is bypassed. To control access:

1. **Use Traefik routing rules** to protect/expose different HTTP methods
2. **Manage users in htpasswd** to control who can perform write operations
3. **Verdaccio config** is set to `$all` because actual enforcement is at the proxy level

If you need granular package-level access control, you would need to:

- Enable Verdaccio's internal authentication
- Configure users in both Traefik and Verdaccio
- Adjust Traefik rules to pass authentication through to Verdaccio

### Local Development Setup

For local testing without a domain:

Access via `localhost`:

```bash
npm config set registry http://localhost/
npm adduser --registry http://localhost/
```

### Backup and Restore

**Backup**:

```bash
# Backup storage
tar -czf verdaccio-backup-$(date +%Y%m%d).tar.gz verdaccio/verdaccio-storage

# Backup configuration
tar -czf verdaccio-config-backup-$(date +%Y%m%d).tar.gz verdaccio/verdaccio-conf
```

**Restore**:

```bash
# Stop services
docker compose down

# Restore storage
tar -xzf verdaccio-backup-YYYYMMDD.tar.gz

# Restore configuration
tar -xzf verdaccio-config-backup-YYYYMMDD.tar.gz

# Start services
docker compose up -d
```

## 🔒 Security Considerations

1. **Always use HTTPS in production** - Uncomment HTTPS configuration to encrypt credentials
2. **Keep htpasswd file secure** - Set proper file permissions (600)
3. **Use strong passwords** - For Traefik Basic Auth users
4. **Method-based authentication** - Write operations (PUT/POST/DELETE/PATCH) require auth, GET requests are public
5. **Authentication is proxy-only** - Verdaccio trusts all requests from Traefik, so secure the proxy
6. **⚠️ Corporate deployment recommendation** - It is **highly recommended** to deploy this registry behind a VPN or internal network when building a full corporate repository. Since read operations (package installations) are publicly accessible by default, restricting network access ensures only organization members can install packages. This is especially important for proprietary packages
7. **VPN/Network isolation** - For corporate use, consider deploying behind:
   - A corporate VPN (WireGuard, OpenVPN, etc.)
   - An internal network with firewall rules
   - A cloud provider's private network (AWS VPC, Azure VNet, etc.)
   - IP allowlisting in Traefik if VPN is not an option
8. **No direct Verdaccio access** - Ensure Verdaccio is only accessible through Traefik
9. **Public read access** - Anyone can download packages; only writes are protected
10. **Regular backups** - Backup storage and configuration regularly
11. **Monitor logs** - Check `docker compose logs` for suspicious activity
12. **Update regularly** - Keep Docker images up to date

## 🐛 Troubleshooting

### Cannot connect to registry

```bash
# Check if services are running
docker compose ps

# View logs
docker compose logs verdaccio
docker compose logs traefik

# Restart services
docker compose restart
```

### Authentication failures

1. **Traefik Basic Auth issues**: Verify `traefik/htpasswd` file exists and has correct format
2. **Check .npmrc**: Ensure base64 encoding is correct and no extra whitespace
3. **Verify credentials**: Make sure username/password match entries in `traefik/htpasswd`
4. **Test with script**: Run `NPM_USER=user NPM_PASS=pass ./test-registry.sh` to verify authentication
5. **Method-based routing**: Authentication only applies to write operations (PUT/POST/DELETE/PATCH)

### HTTPS certificate issues

```bash
# Check acme.json permissions
ls -la traefik/acme.json  # Should be 600

# View Traefik logs for certificate errors
docker compose logs traefik | grep -i acme

# Remove acme.json to start fresh
rm traefik/acme.json && touch traefik/acme.json && chmod 600 traefik/acme.json
docker compose restart traefik
```

### Port conflicts

If port 80 or 443 are already in use:

```yaml
# Edit compose.yml and change host ports
ports:
  - "8080:80"
  - "8443:443"
```

## 📚 Resources

- [Verdaccio Documentation](https://verdaccio.org/docs/what-is-verdaccio)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Docker Documentation](https://docs.docker.com/)
- [npm CLI Documentation](https://docs.npmjs.com/cli/)
- [Let's Encrypt](https://letsencrypt.org/)

## 📄 License

This project is provided as-is for demonstration and production use.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

This is a demo project. Feel free to fork and customize for your needs.

---

**Note**: This setup is intended for development and testing. For production use, consider:

- Using HTTPS/SSL certificates
- Implementing proper backup strategies
- Setting up monitoring and alerting
- Using secrets management for credentials
- Restricting network access appropriately
