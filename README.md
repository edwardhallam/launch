# Launch - GitOps CI/CD Platform

**Automated deployment pipeline for Proxmox homelab services using GitHub Actions**

Launch is a cost-effective GitOps platform that automatically deploys web services and MCP servers from GitHub to your Proxmox infrastructure. Built on self-hosted GitHub Actions runners, it provides zero-cost CI/CD with detailed logging and health monitoring.

## 🎯 Key Features

- **Zero Cost**: Self-hosted runner = unlimited GitHub Actions minutes
- **Service Isolation**: Each service deploys independently via path-based triggers
- **Multiple Deployment Methods**: Docker Compose, LXC containers, direct VM installation
- **Automatic Health Checks**: Scheduled validation of all services
- **Detailed Logging**: Complete deployment logs with troubleshooting information
- **Future AWS Support**: Extensible to cloud deployments

## 🚀 Quick Start

### Prerequisites

- Proxmox VE 8.x server
- GitHub account and repository access
- SSH access to Proxmox host
- Basic understanding of LXC, Docker, and GitHub Actions

### 1. Set Up Self-Hosted Runner

Create an Ubuntu LXC on Proxmox to run GitHub Actions:

```bash
# On Proxmox host
pct create 200 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname github-runner \
  --memory 4096 \
  --cores 2 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --features nesting=1

pct start 200
pct enter 200
```

Inside the LXC:

```bash
# Update system
apt update && apt upgrade -y

# Install Docker
apt install -y docker.io docker-compose curl git

# Add GitHub Actions runner
# Follow instructions from: Settings > Actions > Runners > New self-hosted runner
# Download and configure the runner for Linux x64
```

### 2. Configure GitHub Secrets

In your repository, go to **Settings > Secrets and variables > Actions** and add:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `PROXMOX_API_URL` | Proxmox API endpoint | `https://192.168.1.10:8006/api2/json` |
| `PROXMOX_API_TOKEN` | API token (user@realm!tokenid=secret) | `root@pam!deploy=abc123...` |
| `SSH_PRIVATE_KEY` | SSH private key for deployments | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `DOCKER_HOST_IP` | IP of Docker host LXC | `192.168.1.20` |

### 3. Add Your First Service

```bash
# Copy the service template
cp -r services/_template services/my-service

# Edit the deployment script
nano services/my-service/deploy.sh

# Commit and push
git add services/my-service
git commit -m "Add my-service"
git push origin main

# Deployment automatically triggers!
```

### 4. Monitor Deployment

1. Go to **Actions** tab in GitHub
2. See your workflow running in real-time
3. View detailed logs
4. Check deployment status

## 📁 Repository Structure

```
launch/
├── .github/
│   └── workflows/
│       ├── deploy.yml           # Main deployment workflow
│       └── health-check.yml     # Daily health validation
├── services/
│   ├── _template/               # Copy this for new services
│   ├── example-docker/          # Docker Compose example
│   └── example-lxc/             # LXC creation example
├── scripts/
│   ├── deploy-docker.sh         # Deploy to Docker host
│   ├── deploy-lxc.sh            # Create and configure LXC
│   ├── deploy-vm.sh             # Deploy to existing VM
│   └── health-check.sh          # Service health validation
├── docs/
│   ├── PRD.md                   # Product requirements
│   ├── SETUP.md                 # Detailed setup guide
│   ├── RUNBOOKS.md              # Operational procedures
│   └── TROUBLESHOOTING.md       # Common issues and fixes
└── README.md                    # This file
```

## 🔧 Deployment Methods

### Method 1: Docker Compose

Deploy containerized services to an existing Docker host:

```bash
# Service structure
services/my-app/
├── docker-compose.yml
├── deploy.sh              # Copies files and runs docker-compose up
├── health-check.sh        # Validates service is running
└── README.md
```

**Use Case:** Web apps, databases, microservices

### Method 2: LXC Container

Create a new LXC container and install service:

```bash
# Service structure
services/my-service/
├── deploy.sh              # Creates LXC via Proxmox API
├── config/                # Service configuration files
├── install.sh             # Runs inside LXC after creation
└── README.md
```

**Use Case:** System services, MCP servers, isolated applications

### Method 3: VM Installation

Deploy to existing VM via SSH:

```bash
# Service structure
services/my-tool/
├── deploy.sh              # SSHs to VM and runs install
├── config/                # Configuration files to copy
└── README.md
```

**Use Case:** Services requiring full VM, complex installations

## 🏃 Workflows

### Deployment Workflow

Triggered on push to `main` branch in any `services/*` directory:

1. **Detect Changes**: Path filter identifies which service(s) changed
2. **Run on Self-Hosted**: Job executes on your homelab runner
3. **Execute Deploy Script**: Runs `services/SERVICE_NAME/deploy.sh`
4. **Health Check**: Validates service is running
5. **Report Status**: Updates GitHub commit status

### Health Check Workflow

Runs daily at 6 AM:

1. **Check All Services**: Iterates through all deployed services
2. **Run Health Checks**: Executes `health-check.sh` for each
3. **Report Failures**: Creates GitHub Issue if any service fails

## 📊 Monitoring

### View Deployment Logs

```bash
# In GitHub Actions UI
Actions → Select workflow run → Expand job steps

# Download logs
Actions → Select workflow run → ⋮ → Download log archive
```

### Service Health Status

```bash
# Manual health check
./scripts/health-check.sh my-service

# View scheduled health check results
Actions → Health Check → Latest run
```

## 🔐 Security

### Credential Management

- **Never commit secrets** to the repository
- Use **GitHub Secrets** for static credentials
- Use **1Password CLI** for dynamic secrets
- **Rotate credentials** quarterly

### Runner Security

- Dedicated LXC with minimal privileges
- Firewall rules: Allow outbound HTTPS, SSH to specific hosts
- No inbound connections required
- Regular security updates

### Deployment Security

- SSH key-based authentication only
- Proxmox API token with minimal permissions
- Services run as non-root users
- Network isolation where possible

## 🛠️ Troubleshooting

### Deployment Failed

1. **Check workflow logs** in GitHub Actions
2. **Look for error messages** in deploy.sh output
3. **Verify secrets** are configured correctly
4. **SSH to target** and check manually
5. **Review service logs** on the target system

Common issues:
- **SSH connection refused**: Check network connectivity, SSH key
- **Proxmox API error**: Verify token permissions, API URL
- **Docker container failed**: Check docker-compose.yml syntax, image availability
- **LXC creation failed**: Verify template exists, sufficient resources

### Runner Not Picking Up Jobs

1. **Check runner status** in GitHub Settings > Actions > Runners
2. **SSH to runner LXC** and check service: `systemctl status actions.runner`
3. **View runner logs**: `journalctl -u actions.runner -f`
4. **Restart runner**: `systemctl restart actions.runner`

### Health Check Failing

1. **Run health check manually**: `./scripts/health-check.sh SERVICE_NAME`
2. **Check service status** on target host
3. **Review service logs**
4. **Verify network connectivity** from runner to service

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more details.

## 📚 Documentation

- **[PRD.md](PRD.md)** - Complete product requirements and architecture
- **[SETUP.md](docs/SETUP.md)** - Detailed setup instructions
- **[RUNBOOKS.md](docs/RUNBOOKS.md)** - Operational procedures
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Issue resolution
- **[SERVICE-TEMPLATE.md](services/_template/README.md)** - Service creation guide

## 🗺️ Roadmap

### Phase 1: Foundation ✅
- [x] Repository structure
- [ ] Self-hosted runner setup
- [ ] Basic deployment workflow
- [ ] Example Docker service
- [ ] Documentation

### Phase 2: Core Features
- [ ] Path-based triggering
- [ ] Health check workflow
- [ ] LXC creation via Proxmox API
- [ ] SSH-based deployment
- [ ] Multiple services deployed

### Phase 3: Advanced
- [ ] Rollback automation
- [ ] AWS EC2 deployment
- [ ] Slack/Discord notifications
- [ ] Deployment dashboard
- [ ] Parallel deployments

## 🤝 Contributing

This is a personal project, but feel free to use it as a template for your own infrastructure!

### Adding a New Service

1. Copy `services/_template/` to `services/YOUR_SERVICE/`
2. Update `deploy.sh` with your deployment logic
3. Add service-specific configuration
4. Test locally first
5. Commit and push to trigger deployment

### Improving Documentation

- Found a bug? Open an issue
- Have a better approach? Document it in discussions
- Created a useful script? Add it to `scripts/`

## 📄 License

MIT License - Feel free to use and modify for your own infrastructure.

## 🙏 Acknowledgments

Built with:
- [GitHub Actions](https://github.com/features/actions)
- [Proxmox VE](https://www.proxmox.com/en/proxmox-ve)
- [Docker](https://www.docker.com/)
- Lots of coffee ☕

---

**Need help?** Check the [SETUP.md](docs/SETUP.md) guide or open an issue.
