# Example Service Template

This is a template service demonstrating how to create deployable services in the Launch platform.

## Overview

This template provides:
- **deploy.sh**: Service deployment script with multiple deployment method examples
- **health-check.sh**: Service health validation script
- **docker-compose.yml**: Example Docker Compose configuration
- **README.md**: This documentation file

## Quick Start

### 1. Copy This Template

```bash
cp -r services/example-service services/my-new-service
cd services/my-new-service
```

### 2. Customize Configuration

Edit the following files:

**deploy.sh**:
- Choose a deployment method (Docker, LXC, VM, or custom)
- Uncomment the appropriate deployment script or write custom logic
- Update service-specific configuration

**health-check.sh**:
- Choose a health check method (HTTP, Docker, port, process, or custom)
- Uncomment and configure the appropriate check
- Update service endpoints and names

**docker-compose.yml** (if using Docker method):
- Update service names, ports, and images
- Configure environment variables
- Add volumes and networks as needed

### 3. Test Locally

```bash
# Set required environment variables
export DOCKER_HOST_IP="192.168.1.20"
export SERVICE_NAME="my-new-service"
export PROXMOX_API_URL="https://proxmox.local:8006/api2/json"
export PROXMOX_API_TOKEN="user@realm!tokenid=secret"

# Test deployment script
./deploy.sh

# Test health check
./health-check.sh
```

### 4. Deploy via GitHub

```bash
# Commit and push
git add .
git commit -m "Add my-new-service"
git push origin main
```

The GitHub Actions workflow will automatically:
1. Detect changes in `services/my-new-service/`
2. Execute `deploy.sh` on the self-hosted runner
3. Run `health-check.sh` after 10 seconds
4. Upload deployment logs as artifacts

## Deployment Methods

### Method 1: Docker Compose

**Use when**: Deploying containerized applications to existing Docker host

**Requirements**:
- Docker host LXC configured (default: 192.168.1.20)
- `docker-compose.yml` in service directory
- SSH access to Docker host

**Configuration**:
```bash
# In deploy.sh, uncomment:
../../scripts/deploy-docker.sh
```

**What it does**:
1. Copies service directory to `/opt/services/<service-name>/` on Docker host
2. Runs `docker-compose up -d`
3. Shows container status

### Method 2: Create New LXC

**Use when**: Creating dedicated LXC container for service

**Requirements**:
- Proxmox API access
- LXC template available
- Configuration for LXC specs (CPU, memory, storage)

**Configuration**:
```bash
# In deploy.sh, uncomment:
../../scripts/deploy-lxc.sh
```

**Status**: 🚧 Not yet implemented (see TASKS.md TASK-004)

### Method 3: Deploy to Existing VM

**Use when**: Deploying to pre-existing VM infrastructure

**Requirements**:
- SSH access to target VM
- Installation script for software
- VM pre-configured with dependencies

**Configuration**:
```bash
# In deploy.sh, uncomment:
../../scripts/deploy-vm.sh
```

**Status**: 🚧 Not yet implemented (see TASKS.md TASK-005)

### Method 4: Custom Deployment

**Use when**: None of the standard methods fit your needs

**Configuration**:
Write deployment logic directly in `deploy.sh`:

```bash
echo "Deploying custom service..."
ssh user@host "bash -s" < install.sh
# ... custom logic ...
exit 0
```

## Health Check Patterns

### HTTP Health Check

Best for web services with health endpoints:

```bash
SERVICE_URL="http://192.168.1.20:8080/health"

if curl -f -s -o /dev/null -w "%{http_code}" "$SERVICE_URL" | grep -q "200"; then
    echo "✅ HTTP health check passed"
    exit 0
else
    echo "❌ HTTP health check failed"
    exit 1
fi
```

### Docker Container Check

Best for Docker-based services:

```bash
DOCKER_HOST="root@${DOCKER_HOST_IP}"
CONTAINER_NAME="my-service"

STATUS=$(ssh "$DOCKER_HOST" "docker inspect -f '{{.State.Status}}' $CONTAINER_NAME")

if [ "$STATUS" = "running" ]; then
    echo "✅ Container is running"
    exit 0
else
    echo "❌ Container is $STATUS"
    exit 1
fi
```

### Port Check

Best for network services:

```bash
SERVICE_HOST="192.168.1.20"
SERVICE_PORT="8080"

if nc -z -w5 "$SERVICE_HOST" "$SERVICE_PORT"; then
    echo "✅ Port $SERVICE_PORT is open"
    exit 0
else
    echo "❌ Port $SERVICE_PORT is not accessible"
    exit 1
fi
```

### Process Check

Best for VM/LXC services:

```bash
SSH_HOST="root@192.168.1.20"
PROCESS_NAME="my-service"

if ssh "$SSH_HOST" "pgrep -f $PROCESS_NAME" &>/dev/null; then
    echo "✅ Process $PROCESS_NAME is running"
    exit 0
else
    echo "❌ Process $PROCESS_NAME is not running"
    exit 1
fi
```

## Environment Variables

Available during deployment:

- `PROXMOX_API_URL`: Proxmox API endpoint
- `PROXMOX_API_TOKEN`: Proxmox authentication token
- `DOCKER_HOST_IP`: IP address of Docker host LXC
- `SERVICE_NAME`: Name of the service being deployed
- `SSH_PRIVATE_KEY`: SSH private key (injected at runtime)

## File Structure

```
services/my-service/
├── deploy.sh              # Main deployment script (executable)
├── health-check.sh        # Health validation script (executable)
├── docker-compose.yml     # Docker Compose config (if using Docker)
├── README.md              # Service documentation
├── config/                # Configuration files
│   ├── nginx.conf
│   └── .env.example
└── scripts/               # Service-specific scripts
    └── install.sh
```

## Best Practices

1. **Always test locally** before pushing to GitHub
2. **Use `set -e`** in scripts to fail fast on errors
3. **Log progress** with descriptive echo statements
4. **Handle secrets properly** - use GitHub Secrets, never commit secrets
5. **Keep health checks simple** - should complete in < 60 seconds
6. **Document dependencies** in service README
7. **Version your configuration** - commit docker-compose.yml and configs
8. **Make scripts idempotent** - safe to run multiple times

## Troubleshooting

### Deployment fails with timeout

- Check deployment script runs in < 600 seconds
- Simplify deployment steps or increase timeout in workflow

### Health check fails

- Verify service has time to start (workflow waits 10s)
- Test health check script locally
- Check service logs on target host

### Cannot connect to Docker host

- Verify `DOCKER_HOST_IP` secret is correct
- Check SSH key has access to Docker host
- Test SSH connection from runner: `ssh root@${DOCKER_HOST_IP} docker ps`

### Service not accessible after deployment

- Check firewall rules on target host
- Verify port mappings in docker-compose.yml
- Check network configuration

## References

- **Setup Guide**: docs/SETUP.md
- **Quick Start**: docs/QUICKSTART.md
- **Troubleshooting**: docs/TROUBLESHOOTING.md
- **Task Tracker**: TASKS.md
- **Main Documentation**: CLAUDE.md

## Example Services

Coming soon:
- **nginx-static**: Static file server
- **mcp-server**: MCP server deployment
- **nodejs-api**: Node.js API service
- **python-worker**: Background worker service
