# Launch Setup Guide

Complete step-by-step instructions for setting up the Launch CI/CD platform.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Proxmox Preparation](#proxmox-preparation)
3. [GitHub Repository Setup](#github-repository-setup)
4. [Self-Hosted Runner Installation](#self-hosted-runner-installation)
5. [Docker Host Setup](#docker-host-setup)
6. [Testing the Pipeline](#testing-the-pipeline)
7. [Adding Services](#adding-services)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Infrastructure
- Proxmox VE 8.x server with available resources:
  - 2-4 GB RAM for runner LXC
  - 2-4 GB RAM for Docker host LXC (if using Docker)
  - 20+ GB disk space
- Network connectivity between components
- SSH access to Proxmox host

### Required Accounts
- GitHub account with admin access to repository
- Proxmox user with API token privileges

### Local Tools
- SSH client
- Git
- Text editor
- Web browser

## Proxmox Preparation

### 1. Create API Token

```bash
# SSH to Proxmox host
ssh root@proxmox.local

# Create a user for automation (if not using root)
pveum user add automation@pve
pveum acl modify / -user automation@pve -role Administrator

# Create API token
pveum user token add automation@pve deploy -privsep 0

# Save the token ID and secret - you'll need these for GitHub Secrets
# Format: automation@pve!deploy
# Secret: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### 2. Download Container Template

```bash
# Download Ubuntu 22.04 LXC template
pveam update
pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
```

### 3. Prepare Network

Ensure your LXCs will have:
- IP addresses (DHCP or static)
- Internet connectivity for pulling packages/images
- Connectivity to Proxmox API
- SSH access from runner

## GitHub Repository Setup

### 1. Create Repository

```bash
# Clone this repository or create new one
git clone https://github.com/YOUR_USERNAME/launch.git
cd launch

# Or initialize new repository
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/launch.git
git push -u origin main
```

### 2. Configure Secrets

Go to repository **Settings > Secrets and variables > Actions > New repository secret**

Add these secrets:

| Name | Value | How to Get |
|------|-------|------------|
| `PROXMOX_API_URL` | `https://192.168.1.10:8006/api2/json` | Your Proxmox host IP + port |
| `PROXMOX_API_TOKEN` | `automation@pve!deploy=xxxxx...` | Token from step 1 |
| `SSH_PRIVATE_KEY` | `-----BEGIN OPENSSH PRIVATE KEY-----...` | Generate new SSH key pair |
| `DOCKER_HOST_IP` | `192.168.1.20` | IP of Docker host LXC (if using Docker) |

**To generate SSH key:**
```bash
# On your local machine
ssh-keygen -t ed25519 -C "launch-ci" -f ~/.ssh/launch-ci

# Copy private key content to GITHUB_SECRETS
cat ~/.ssh/launch-ci

# Save public key for later
cat ~/.ssh/launch-ci.pub
```

## Self-Hosted Runner Installation

### 1. Create Runner LXC

```bash
# SSH to Proxmox host
ssh root@proxmox.local

# Create LXC container
pct create 200 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname github-runner \
  --memory 4096 \
  --cores 2 \
  --rootfs local-lvm:20 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --features nesting=1 \
  --unprivileged 1 \
  --start 1

# Wait for container to start
sleep 10

# Enter container
pct enter 200
```

### 2. Install Dependencies

Inside the runner LXC:

```bash
# Update system
apt update && apt upgrade -y

# Install required packages
apt install -y \
  curl \
  git \
  jq \
  ca-certificates \
  gnupg \
  lsb-release \
  openssh-client

# Install Docker
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# Verify Docker
docker --version
```

### 3. Install GitHub Actions Runner

Still inside the runner LXC:

```bash
# Create a directory for the runner
mkdir -p /opt/actions-runner
cd /opt/actions-runner

# Download the latest runner package
# Go to your GitHub repo > Settings > Actions > Runners > New self-hosted runner
# Copy the download URL shown there, example:
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

# Extract the installer
tar xzf ./actions-runner-linux-x64-*.tar.gz

# Configure the runner
# You'll need the URL and token from GitHub (Settings > Actions > Runners > New runner)
./config.sh --url https://github.com/YOUR_USERNAME/launch --token YOUR_RUNNER_TOKEN

# When prompted:
# - Name: github-runner (or leave default)
# - Work folder: _work (leave default)
# - Additional labels: proxmox,docker (optional)

# Install as a service
sudo ./svc.sh install

# Start the service
sudo ./svc.sh start

# Check status
sudo ./svc.sh status
```

### 4. Configure SSH Key

Still inside the runner LXC:

```bash
# Create .ssh directory
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# The SSH private key will be injected by GitHub Actions at runtime
# But for manual testing, you can add it now:
nano /root/.ssh/id_ed25519
# Paste the private key content
chmod 600 /root/.ssh/id_ed25519

# Add Proxmox host to known_hosts
ssh-keyscan proxmox.local >> /root/.ssh/known_hosts
```

### 5. Test Runner

```bash
# Exit the LXC
exit

# On Proxmox host, verify runner is running
pct exec 200 -- systemctl status actions.runner

# Check GitHub repository
# Settings > Actions > Runners should show your runner as "Idle"
```

## Docker Host Setup

### 1. Create Docker Host LXC

```bash
# On Proxmox host
pct create 201 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname docker-host \
  --memory 4096 \
  --cores 2 \
  --rootfs local-lvm:50 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --features nesting=1 \
  --unprivileged 1 \
  --start 1

# Enter container
pct enter 201
```

### 2. Install Docker

Inside the Docker host LXC:

```bash
# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# Install Docker Compose
apt install -y docker-compose

# Create directory for services
mkdir -p /opt/services

# Test Docker
docker run hello-world
```

### 3. Configure SSH Access

Still inside the Docker host:

```bash
# Ensure SSH is installed
apt install -y openssh-server
systemctl enable ssh
systemctl start ssh

# Add runner's public key to authorized_keys
mkdir -p /root/.ssh
nano /root/.ssh/authorized_keys
# Paste the public key from ~/.ssh/launch-ci.pub

chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
```

### 4. Get IP Address

```bash
# Note the IP address - you'll need it for DOCKER_HOST_IP secret
ip addr show eth0 | grep "inet "
# Example output: inet 192.168.1.20/24

# Exit container
exit
```

## Testing the Pipeline

### 1. Test SSH Connectivity

From the runner LXC, test connecting to Docker host:

```bash
# On Proxmox host
pct enter 200  # Enter runner

# Test SSH (replace with your Docker host IP)
ssh -i /root/.ssh/id_ed25519 root@192.168.1.20 "echo 'SSH works'"

# Exit runner
exit
```

### 2. Create Test Service

```bash
# On your local machine, in the repository
cp -r services/example-service services/test-service

# Edit deploy script to use Docker deployment
cd services/test-service
nano deploy.sh
```

Uncomment the Docker deployment line:
```bash
../../scripts/deploy-docker.sh
```

### 3. Trigger Deployment

```bash
# Commit and push
git add services/test-service
git commit -m "Add test service"
git push origin main

# Watch deployment in GitHub Actions
# Go to: https://github.com/YOUR_USERNAME/launch/actions
```

### 4. Verify Deployment

```bash
# SSH to Docker host
ssh root@DOCKER_HOST_IP

# Check running containers
docker ps

# Check service directory
ls -la /opt/services/test-service/

# View logs
cd /opt/services/test-service
docker-compose logs
```

## Adding Services

### 1. Create New Service

```bash
# Copy template
cp -r services/example-service services/my-new-service

# Edit deployment script
cd services/my-new-service
nano deploy.sh

# Edit docker-compose.yml (if using Docker)
nano docker-compose.yml

# Edit health check
nano health-check.sh

# Update README
nano README.md
```

### 2. Configure Service

Add any configuration files:
```bash
mkdir -p config
# Add your config files to config/
```

Create `.env` file if needed:
```bash
nano .env
# Add environment variables
# Note: Don't commit secrets to git!
```

### 3. Deploy

```bash
# Test locally first (optional)
export DOCKER_HOST_IP="192.168.1.20"
export SERVICE_NAME="my-new-service"
./deploy.sh

# If test successful, commit and push
git add .
git commit -m "Add my-new-service"
git push origin main
```

## Troubleshooting

### Runner Not Showing in GitHub

**Problem:** Runner doesn't appear in Settings > Actions > Runners

**Solutions:**
1. Check runner service status:
   ```bash
   pct exec 200 -- systemctl status actions.runner
   ```

2. Check runner logs:
   ```bash
   pct exec 200 -- journalctl -u actions.runner -f
   ```

3. Verify network connectivity:
   ```bash
   pct exec 200 -- curl -I https://github.com
   ```

4. Reconfigure runner:
   ```bash
   pct enter 200
   cd /opt/actions-runner
   ./config.sh remove --token YOUR_TOKEN
   ./config.sh --url https://github.com/YOUR_USERNAME/launch --token NEW_TOKEN
   sudo ./svc.sh install
   sudo ./svc.sh start
   ```

### Deployment Fails with SSH Error

**Problem:** Cannot connect to Docker host

**Solutions:**
1. Verify SSH key is correct:
   ```bash
   # Check GitHub secret matches
   cat /root/.ssh/id_ed25519  # On runner
   ```

2. Test SSH manually:
   ```bash
   pct exec 200 -- ssh root@DOCKER_HOST_IP "echo test"
   ```

3. Check authorized_keys:
   ```bash
   pct exec 201 -- cat /root/.ssh/authorized_keys
   ```

4. Verify firewall:
   ```bash
   pct exec 201 -- ufw status  # If using ufw
   ```

### Deployment Succeeds but Service Not Running

**Problem:** Deploy workflow passes but service doesn't work

**Solutions:**
1. Check service logs:
   ```bash
   ssh root@DOCKER_HOST_IP
   cd /opt/services/SERVICE_NAME
   docker-compose logs
   ```

2. Check container status:
   ```bash
   docker ps -a | grep SERVICE_NAME
   ```

3. Run health check manually:
   ```bash
   # In your local repo
   cd services/SERVICE_NAME
   export DOCKER_HOST_IP="192.168.1.20"
   ./health-check.sh
   ```

4. Review deployment logs in GitHub Actions

### Proxmox API Errors

**Problem:** Cannot create/manage LXCs via API

**Solutions:**
1. Test API token:
   ```bash
   curl -k -H "Authorization: PVEAPIToken=USER@REALM!TOKENID=SECRET" \
     https://PROXMOX_IP:8006/api2/json/nodes
   ```

2. Verify token permissions:
   ```bash
   # On Proxmox
   pveum user token list automation@pve
   ```

3. Check API URL format:
   - Must include `/api2/json`
   - Must use `https://`
   - Port is usually `8006`

## Next Steps

Once setup is complete:

1. ✅ Runner is online and idle in GitHub
2. ✅ Test deployment succeeded
3. ✅ Health checks passing
4. ✅ Can SSH from runner to targets

You're ready to:
- Add production services
- Set up monitoring/alerting
- Configure backups
- Explore AWS deployment (Phase 3)

---

**Need Help?**
- Review [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
- Check [PRD.md](../PRD.md) for architecture details
- Open an issue in GitHub
