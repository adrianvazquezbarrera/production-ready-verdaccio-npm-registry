# Production ready NPM Registry

A self-hosted private npm registry powered by [Verdaccio](https://verdaccio.org/), containerized with Docker for easy deployment and testing.

## 📋 Overview

This project provides a ready-to-use Verdaccio npm registry setup with:

- **Docker Compose** configuration for easy orchestration
- **Dynamic user management** via environment variables
- **Persistent storage** for packages and configuration
- **CI/CD integration** scripts for automated workflows
- **htpasswd authentication** for secure access

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose installed
- Node.js and npm (for local package publishing)

### Start the Registry

```bash
# Start with default users (alice:password1, bob:password2)
docker compose up -d

```

The registry will be available at: **http://localhost:4873**

### Verify Installation

```bash
# Check if the registry is running
curl http://localhost:4873
```

## 🔐 Authentication

### Manual Login

```bash
npm login --registry http://localhost:4873
# Username: alice (or bob)
# Password: password1 (or password2)
# Email: (any valid email)
```

### CI/CD Login

Use the provided `ci-login.sh` script for automated authentication:

```bash
# With defaults (bob:password2)
./ci-login.sh

# With custom credentials
NPM_USER=alice NPM_PASS=password1 NPM_EMAIL=alice@example.com ./ci-login.sh

# With custom registry URL
NPM_REGISTRY_URL=http://verdaccio:4873 NPM_REGISTRY=verdaccio:4873 ./ci-login.sh
```

This script:

- Creates a `.npmrc` file with base64-encoded credentials
- Verifies registry connectivity with `npm ping`
- Warns about potential conflicts with global `~/.npmrc`
- Provides guidance for initial setup with `npm adduser`

### GitHub Actions Example

```yaml
- name: Authenticate to Verdaccio
  run: |
    AUTH=$(echo -n "${{ secrets.NPM_USER }}:${{ secrets.NPM_PASS }}" | base64 | tr -d '\n')
    cat > ~/.npmrc << EOF
    registry=http://localhost:4873
    //localhost:4873/:_auth=$AUTH
    //localhost:4873/:email=ci@example.com
    EOF

- name: Verify Registry Connection
  run: npm ping
```

**Note**: If you encounter authentication issues, you may need to run `npm adduser --registry=http://localhost:4873` once to establish initial connectivity with the registry.

## 📦 Usage

### Publishing Packages

```bash
# Set registry for current project
npm config set registry http://localhost:4873

# Or publish directly to the registry
npm publish --registry http://localhost:4873
```

### Installing Packages

```bash
# Install from private registry
npm install my-package --registry http://localhost:4873

# Or configure registry globally
npm config set registry http://localhost:4873
npm install my-package
```

## ⚙️ Configuration

### Environment Variables

Configure users via the `VERDACCIO_USERS` environment variable in `compose.yml`:

```yaml
environment:
  - VERDACCIO_USERS=alice:password1,bob:password2,charlie:password3
```

### Verdaccio Configuration

The main configuration file is located at `verdaccio/verdaccio-conf/config.yaml`:

- **Authentication**: htpasswd-based with up to 1000 users
- **Access Control**: Authenticated users can access and publish all packages
- **Uplinks**: Proxies to npmjs.org for public packages
- **Audit**: Enabled for security logging

### Storage

Packages are stored persistently in:

```
./verdaccio/verdaccio-storage/
```

This directory is mounted as a volume and persists between container restarts.

## 🏗️ Project Structure

```
.
├── compose.yml                    # Docker Compose configuration
├── Dockerfile                     # Verdaccio container image
├── entrypoint.sh                  # Container startup script with user creation
├── ci-login.sh                    # CI/CD authentication helper
└── verdaccio/
    ├── verdaccio-conf/
    │   ├── config.yaml            # Verdaccio configuration
    │   └── htpasswd               # Generated user credentials
    └── verdaccio-storage/         # Package storage (persistent)
```

## 🔧 Advanced Usage

### Add Users

Users are created at container startup from the `VERDACCIO_USERS` environment variable. To add users:

1. Stop the container
2. Update the `VERDACCIO_USERS` variable in `compose.yml`
3. Restart the container

```bash
docker-compose down
# Edit compose.yml
docker-compose up -d
```

### Custom Configuration

Edit `verdaccio/verdaccio-conf/config.yaml` to customize:

- Package access rules
- Uplink registries
- Logging levels
- Plugin configuration

After changes, restart the container:

```bash
docker-compose restart
```

## 📚 Resources

- [Verdaccio Documentation](https://verdaccio.org/docs/what-is-verdaccio)
- [Docker Documentation](https://docs.docker.com/)
- [npm CLI Documentation](https://docs.npmjs.com/cli/)

## 📄 License

This project is provided as-is for demonstration and testing purposes.

## 🤝 Contributing

This is a demo project. Feel free to fork and customize for your needs.

---

**Note**: This setup is intended for development and testing. For production use, consider:

- Using HTTPS/SSL certificates
- Implementing proper backup strategies
- Setting up monitoring and alerting
- Using secrets management for credentials
- Restricting network access appropriately
