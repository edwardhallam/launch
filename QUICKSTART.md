# Launch - Quick Start

**Get your CI/CD pipeline running in 30 minutes**

## Prerequisites Checklist

- [ ] Proxmox VE 8.x server running
- [ ] GitHub repository created
- [ ] SSH access to Proxmox

## Step 1: Set Up Self-Hosted Runner (10 min)

```bash
# On Proxmox host
ssh root@proxmox.local

# Create runner LXC
pct create 200 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname github-runner \
  --memory 4096 \
  --cores 2 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --features nesting=1 \
  --start 1

# Install dependencies
pct enter 200
apt update && apt upgrade -y
apt install -y curl git jq docker.io docker-compose

# Install GitHub Actions runner
mkdir -p /opt/actions-runner && cd /opt/actions-runner
curl -o actions-runner.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf actions-runner.tar.gz

# Configure (get token from: GitHub repo > Settings > Actions > Runners > New)
./config.sh --url https://github.com/YOUR_USERNAME/launch --token YOUR_TOKEN
sudo ./svc.sh install && sudo ./svc.sh start

exit
```

## Step 2: Set Up Docker Host (5 min)

```bash
# Create Docker host LXC
pct create 201 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname docker-host \
  --memory 4096 \
  --cores 2 \
  --rootfs local-lvm:50 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --features nesting=1 \
  --start 1

# Install Docker
pct enter 201
apt update && apt install -y curl docker.io docker-compose openssh-server
mkdir -p /opt/services
systemctl enable docker ssh
exit

# Get Docker host IP
pct exec 201 -- ip addr show eth0 | grep "inet "
# Note the IP for later (e.g., 192.168.1.20)
```

## Step 3: Configure SSH (5 min)

```bash
# On your local machine
ssh-keygen -t ed25519 -C "launch-ci" -f ~/.ssh/launch-ci

# Copy private key to GitHub Secrets (we'll do this in Step 4)
cat ~/.ssh/launch-ci

# Add public key to Docker host
ssh-copy-id -i ~/.ssh/launch-ci.pub root@DOCKER_HOST_IP

# Test from runner
pct exec 200 -- ssh -i /root/.ssh/id_ed25519 root@DOCKER_HOST_IP "echo SSH works"
```

## Step 4: Configure GitHub Secrets (5 min)

Go to: **Your Repository > Settings > Secrets and variables > Actions > New repository secret**

Add these 4 secrets:

| Name | Value |
|------|-------|
| `PROXMOX_API_URL` | `https://YOUR_PROXMOX_IP:8006/api2/json` |
| `PROXMOX_API_TOKEN` | Create with: `pveum user token add root@pam deploy` |
| `SSH_PRIVATE_KEY` | Content of `~/.ssh/launch-ci` |
| `DOCKER_HOST_IP` | IP from Step 2 (e.g., `192.168.1.20`) |

## Step 5: Deploy Test Service (5 min)

```bash
# Clone this repository
git clone https://github.com/YOUR_USERNAME/launch.git
cd launch

# Create test service
cp -r services/example-service services/nginx-test

# Edit deploy script to use Docker
nano services/nginx-test/deploy.sh
# Uncomment: ../../scripts/deploy-docker.sh

# Make executable
chmod +x services/nginx-test/deploy.sh

# Commit and push
git add services/nginx-test
git commit -m "Add nginx test service"
git push origin main
```

## Step 6: Verify Deployment

1. **Watch GitHub Actions:**
   - Go to repository > Actions tab
   - See workflow running
   - Check logs for success

2. **Verify on Docker host:**
   ```bash
   ssh root@DOCKER_HOST_IP
   docker ps
   curl http://localhost:8080
   ```

3. **Check health:**
   - Wait for daily health check workflow
   - Or trigger manually: Actions > Health Check > Run workflow

## Troubleshooting

**Runner not showing:**
```bash
pct exec 200 -- systemctl status actions.runner
pct exec 200 -- journalctl -u actions.runner -f
```

**SSH fails:**
```bash
# Test from runner
pct exec 200 -- ssh -v root@DOCKER_HOST_IP
```

**Deployment fails:**
- Check Actions logs
- Verify secrets are set
- Test SSH connectivity

## What's Next?

You now have a working CI/CD pipeline! Next steps:

1. **Add Real Services:**
   - Copy example-service template
   - Customize for your needs
   - Push to deploy

2. **Enhance Security:**
   - Rotate SSH keys regularly
   - Use 1Password for secrets
   - Enable 2FA on GitHub

3. **Monitor:**
   - Set up Prometheus/Grafana
   - Configure alerts
   - Review logs regularly

4. **AWS Integration (Phase 3):**
   - Create AWS account
   - Set up EC2 deployment
   - Test cloud deployments

## Full Documentation

- **[README.md](../README.md)** - Complete overview
- **[SETUP.md](./SETUP.md)** - Detailed setup guide
- **[PRD.md](../PRD.md)** - Architecture and requirements
- **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Issue resolution

---

**Questions?** Open an issue in GitHub!
