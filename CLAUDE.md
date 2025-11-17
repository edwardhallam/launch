# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Launch is a zero-cost GitOps CI/CD platform that automates deployment of web services and MCP servers from GitHub to Proxmox infrastructure using self-hosted GitHub Actions runners. Built for homelab deployments with future AWS extensibility.

**Key Characteristics:**
- Self-hosted GitHub Actions runner eliminates costs (unlimited build minutes)
- Path-based service isolation: changes to `services/*/` trigger only that service's deployment
- Multiple deployment targets: Docker Compose, LXC containers, direct VM installation
- Deployed services are monitored via automated health checks

## Essential Commands

### Development & Testing

```bash
# Test deployment script locally (set required env vars first)
export DOCKER_HOST_IP="192.168.1.20"
export SERVICE_NAME="my-service"
cd services/my-service
./deploy.sh

# Test health check locally
cd services/my-service
./health-check.sh

# Validate GitHub Actions workflows
gh workflow list
gh workflow view deploy
```

### Working with Services

```bash
# Create new service from template
cp -r services/example-service services/my-new-service
cd services/my-new-service

# Make deployment script executable
chmod +x deploy.sh health-check.sh

# Deploy (triggers via git push)
git add .
git commit -m "Add my-new-service"
git push origin main  # Auto-triggers deployment workflow
```

### Debugging Deployments

```bash
# View workflow runs
gh run list --workflow=deploy.yml

# Watch specific run
gh run view <run-id> --log

# SSH to Docker host to check service
ssh root@${DOCKER_HOST_IP}
cd /opt/services/<service-name>
docker-compose ps
docker-compose logs

# Check runner status
ssh root@<proxmox-host>
pct exec 200 -- systemctl status actions.runner
pct exec 200 -- journalctl -u actions.runner -f
```

## Architecture

### Deployment Flow

1. **Trigger**: Push to `main` with changes in `services/*/` paths
2. **Detection**: `.github/workflows/deploy.yml` detects changed services via git diff
3. **Isolation**: Only services with changes are deployed (parallel execution, max 2 concurrent)
4. **Execution**: Self-hosted runner executes `services/<service-name>/deploy.sh`
5. **Health Check**: Runs `services/<service-name>/health-check.sh` if present
6. **Logging**: All output captured as GitHub Actions artifact (90-day retention)

### Component Layout

```
GitHub Actions (orchestration)
    ↓ webhook
Self-Hosted Runner (LXC 200)
    ├─→ Proxmox API (create/manage LXC/VM)
    ├─→ SSH (deploy to containers/VMs)
    └─→ Docker API (container deployments)
```

### Key Directories

- `.github/workflows/`: GitHub Actions workflow definitions
  - `deploy.yml`: Main deployment workflow (path-filtered triggers)
  - `health-check.yml`: Daily scheduled health validation
- `services/`: Individual service configurations (each isolated)
  - `example-service/`: Template with all deployment methods
  - Each service has: `deploy.sh`, `health-check.sh`, `docker-compose.yml`, `README.md`
- `scripts/`: Shared deployment helpers
  - Currently only `deploy-docker.sh` exists (deployed services should use `../../scripts/deploy-docker.sh`)

### Secrets Management

Required GitHub Secrets (repository settings):
- `PROXMOX_API_URL`: Proxmox API endpoint (`https://IP:8006/api2/json`)
- `PROXMOX_API_TOKEN`: API token format `user@realm!tokenid=secret`
- `SSH_PRIVATE_KEY`: SSH private key for deployments (injected at runtime)
- `DOCKER_HOST_IP`: IP of Docker host LXC for container deployments

**Critical**: Never commit secrets. Use GitHub Secrets for static credentials, 1Password CLI for dynamic secrets.

## Service Development Patterns

### Creating a New Service

1. Copy template: `cp -r services/example-service services/<name>`
2. Choose deployment method in `deploy.sh`:
   - **Docker Compose**: Uncomment `../../scripts/deploy-docker.sh` (requires `docker-compose.yml`)
   - **LXC Creation**: Uncomment `../../scripts/deploy-lxc.sh` (not yet implemented - see FR4 in PRD.md)
   - **VM Deployment**: Uncomment `../../scripts/deploy-vm.sh` (not yet implemented - see FR4 in PRD.md)
   - **Custom**: Write deployment logic directly in `deploy.sh`
3. Configure health check in `health-check.sh` (examples provided)
4. Test locally before committing
5. Push to `main` to trigger deployment

### Deployment Script Requirements

- Must be executable (`chmod +x deploy.sh`)
- Must exit 0 on success, non-zero on failure
- Must handle errors gracefully (`set -e`)
- Should log progress with descriptive messages
- Timeout: 600 seconds (10 minutes) enforced by workflow
- Available environment variables: `PROXMOX_API_URL`, `PROXMOX_API_TOKEN`, `DOCKER_HOST_IP`, `SERVICE_NAME`

### Health Check Requirements

- Must exit 0 if healthy, non-zero if unhealthy
- Timeout: 60 seconds enforced by workflow
- Should wait for service startup (workflow waits 10s before running)
- Common patterns provided in template (HTTP, Docker container status, port check, process check)
- Runs after deployment and daily via scheduled workflow

## Workflow Behavior

### Path-Based Triggering

- Workflow only triggers on changes to `services/**` paths
- Multiple changed services deploy in parallel (max 2 concurrent)
- Unchanged services are not affected
- Each service deployment is independent (fail-fast: false)

### Deployment Steps (per service)

1. **Validate**: Check service directory and `deploy.sh` exist
2. **Pre-deployment checks**: Log environment info
3. **Deploy**: Execute `deploy.sh` with 600s timeout
4. **Health check**: Run `health-check.sh` after 10s wait (if exists)
5. **Upload logs**: Store `deploy.log` as artifact
6. **Summary**: Add deployment details to GitHub step summary

### Health Check Workflow

- **Schedule**: Daily at 6 AM UTC (or manual trigger)
- **Discovery**: Finds all services with `health-check.sh`
- **Execution**: Runs each health check with 60s timeout
- **Reporting**: Creates GitHub Issue if any service fails
- **Labels**: Issues tagged with `health-check` and `automated`

## Development Guidelines

### When Adding New Features

1. **New deployment method**: Create script in `scripts/` directory, update template in `services/example-service/deploy.sh`
2. **New workflow**: Add to `.github/workflows/`, document in this file
3. **Secrets**: Add to GitHub Secrets, document in "Secrets Management" section above
4. **Testing**: Always test locally before committing, use feature branches for experimentation

### Current Limitations (Phase 1)

- LXC creation via Proxmox API not implemented (see PRD.md Phase 2)
- VM SSH deployment helper not implemented (see PRD.md Phase 2)
- No rollback automation (manual via re-running old commit)
- No AWS support yet (see PRD.md Phase 3)
- No notification integrations (Slack/Discord - see deploy.yml:160)

### File Structure Conventions

- All bash scripts must use `#!/bin/bash` shebang
- All scripts must use `set -e` for error handling
- Deployment scripts must be in service root: `services/<name>/deploy.sh`
- Health checks must be in service root: `services/<name>/health-check.sh`
- Docker services must have `docker-compose.yml` in service root
- Configuration files go in `services/<name>/config/` directory

## Common Pitfalls

1. **Forgetting to make scripts executable**: Always `chmod +x deploy.sh health-check.sh`
2. **Missing docker-compose.yml**: Required when using `deploy-docker.sh`
3. **SSH key issues**: Private key injected at runtime, test SSH connectivity from runner
4. **Path filters**: Workflow only triggers on `services/**` changes (not docs, scripts, etc.)
5. **Timeout errors**: Deploy must complete in 600s, health check in 60s
6. **Secrets in logs**: Workflows should never log secret values (already configured with `set +x` practices)

## Important References

- **Setup Guide**: docs/SETUP.md (comprehensive setup instructions)
- **Quick Start**: docs/QUICKSTART.md (30-minute setup)
- **Architecture**: docs/PRD.md (complete product requirements and technical details)
- **Troubleshooting**: docs/TROUBLESHOOTING.md (common issues and solutions)
- **File Index**: docs/FILE-INDEX.md (quick reference to all files)
- **Task Tracker**: TASKS.md (task management for Claude Code)

## Project Status

**Current Phase**: Foundation (Phase 1)
- ✅ Repository structure complete
- ✅ Documentation complete
- ✅ GitHub Actions workflows defined
- ✅ Docker deployment method implemented
- ⏳ Self-hosted runner setup (user action required)
- ⏳ First service deployment (user action required)

**Next Steps**: Follow QUICKSTART.md to set up infrastructure and deploy first service
