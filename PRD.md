# Product Requirements Document: Launch

**Project Name:** Launch  
**Version:** 1.0  
**Date:** November 16, 2025  
**Owner:** Eddie Hallam  
**Status:** Initial Design

## Executive Summary

Launch is a cost-effective GitOps CI/CD platform for automating deployment of web services and MCP servers from GitHub to Proxmox infrastructure (LXCs/VMs) with future AWS support. Built on GitHub Actions with self-hosted runners, it provides zero-cost automated deployments with detailed logging and failure tracking.

## Problem Statement

Current challenges:
- Manual deployment of services to homelab infrastructure
- No automated testing or validation pipeline
- Difficult to track deployment history and failures
- Time-consuming to deploy updates across multiple services
- No standardized deployment process

## Goals & Objectives

### Primary Goals
1. **Automated Deployment**: Push to main triggers automatic deployment per service
2. **Service Isolation**: Each service independently deployed via path-based triggers
3. **Cost Optimization**: Zero cost via self-hosted GitHub Actions runner
4. **Homelab First**: Primary deployment to Proxmox LXCs/VMs
5. **Cloud Ready**: Extensible to AWS EC2 for future needs

### Success Metrics
- Deployment time: < 5 minutes from push to production
- Success rate: > 95% for valid deployments
- Cost: $0/month for core functionality
- Time saved: 80% reduction in manual deployment effort

## Stakeholders

**Primary User:** DevOps Engineer (Eddie)
- Manages Proxmox homelab infrastructure
- Deploys multiple web services and MCP servers
- Values automation, cost-effectiveness, and detailed logging
- Needs easy troubleshooting when deployments fail

## Functional Requirements

### FR1: Repository Structure
**Priority:** P0

Single monorepo containing all service configurations:
```
launch/
├── services/
│   ├── service-a/          # Each service isolated
│   ├── service-b/
│   └── service-n/
├── .github/workflows/       # CI/CD definitions
├── scripts/                 # Shared deployment scripts
└── docs/                    # Documentation
```

**Service Folder Structure:**
```
services/my-service/
├── deploy.sh               # Deployment script
├── docker-compose.yml      # Container config (if applicable)
├── config/                 # Service configuration
├── health-check.sh         # Health validation
└── README.md              # Service documentation
```

### FR2: GitHub Actions Workflows
**Priority:** P0

**Main Deployment Workflow** (`.github/workflows/deploy.yml`):
- Triggered on push to `main` branch
- Path filters: `services/*/` - only deploy changed services
- Runs on self-hosted runner (in homelab)
- Steps:
  1. Checkout code
  2. Identify changed service(s)
  3. Run pre-deployment validation
  4. Execute deployment script
  5. Run health checks
  6. Report status

**Health Check Workflow** (`.github/workflows/health-check.yml`):
- Scheduled: daily at 6 AM
- Validates all deployed services
- Reports failures to GitHub Issues

### FR3: Self-Hosted Runner
**Priority:** P0

**Deployment:**
- Ubuntu 22.04 LXC on Proxmox
- GitHub Actions runner service
- Direct access to Proxmox API
- Docker installed for container deployments

**Benefits:**
- Unlimited build minutes (no cost)
- No VPN/tunnel required
- Fast deployments (local network)
- Full control over environment

### FR4: Deployment Methods
**Priority:** P0

**Support Multiple Deployment Types:**

1. **Docker Compose Services:**
   - Deploy to existing Docker host LXC
   - Pull/build images
   - Update running containers
   - Health check via HTTP/port

2. **LXC Containers:**
   - Create new LXC via Proxmox API
   - Configure networking
   - Install service
   - Start and validate

3. **Direct VM Installation:**
   - SSH to target VM
   - Run installation/update scripts
   - Configure service
   - Enable and start

### FR5: Deployment Targets
**Priority:** P0 (Proxmox), P2 (AWS)

**Proxmox (Primary):**
- LXC containers on Proxmox node
- VMs on Proxmox node  
- Existing Docker host LXC
- Access via Proxmox API + SSH

**AWS (Future/Proof of Concept):**
- EC2 instances
- Deploy via AWS CLI/SDK
- Requires AWS credentials in GitHub Secrets

### FR6: Logging & Monitoring
**Priority:** P0

**Deployment Logs:**
- Capture all stdout/stderr
- Store in GitHub Actions artifacts
- Include timestamps
- Preserve for 90 days

**Failure Handling:**
- Detailed error messages
- Stack traces when available
- Environment information
- Failed state preservation for debugging

**Notifications:**
- GitHub commit status (success/failure)
- Optional: Slack/Discord webhooks
- Email notifications (GitHub settings)

### FR7: Secrets Management
**Priority:** P0

**Required Secrets:**
- Proxmox API credentials
- SSH private keys
- Service-specific credentials (databases, APIs)
- 1Password CLI for runtime secrets

**Storage:**
- GitHub Secrets for static credentials
- 1Password for dynamic/sensitive secrets
- Never commit secrets to repository

### FR8: Rollback Capability
**Priority:** P1

**Manual Rollback:**
- Tag releases in GitHub
- Redeploy specific tag/commit
- Document rollback procedure per service

**Future:** Automated rollback on health check failure

## Non-Functional Requirements

### NFR1: Cost
- **Constraint:** $0/month for core functionality
- Self-hosted runner eliminates GitHub Actions costs
- No third-party CI/CD fees
- Proxmox infrastructure already owned

### NFR2: Performance
- Deployment time: < 5 minutes (95th percentile)
- Build time: < 3 minutes for typical service
- Network transfer: Limited by homelab bandwidth
- Parallel deployments: Up to 2 concurrent

### NFR3: Reliability
- Deployment success rate: > 95%
- Runner uptime: > 99% (LXC on Proxmox)
- Automatic retry for transient failures (3 attempts)
- Graceful failure with detailed logs

### NFR4: Security
- No hardcoded credentials
- SSH key-based authentication
- Proxmox API token with minimal permissions
- Secrets encrypted in GitHub
- Runner isolated from other services

### NFR5: Maintainability
- Clear documentation per service
- Standardized deployment scripts
- Easy to add new services (copy template)
- Version-controlled infrastructure as code

### NFR6: Scalability
- Support 10+ services initially
- Scale to 50+ services over time
- Multiple deployment targets per service
- Queue deployments if multiple triggered

## Technical Architecture

### Component Overview

```
┌─────────────┐
│   GitHub    │
│  Repository │
└──────┬──────┘
       │ push to main
       ▼
┌─────────────────┐
│ GitHub Actions  │
│  (cloud runner) │
└─────┬───────────┘
      │ webhook
      ▼
┌──────────────────┐
│  Self-Hosted     │◄──────── Unlimited builds
│  Runner (LXC)    │          Local network access
└────────┬─────────┘
         │
         ├─► Proxmox API ──► Create/manage LXC/VM
         │
         ├─► SSH ──────────► Deploy to existing containers/VMs
         │
         └─► Docker API ───► Deploy containers

```

### Technology Stack

**CI/CD:**
- GitHub Actions (orchestration)
- Self-hosted runner (Ubuntu 22.04 LXC)

**Infrastructure:**
- Proxmox VE 8.x
- LXC containers (primary target)
- Docker + Docker Compose
- Ubuntu 22.04/24.04 for services

**Deployment Tools:**
- Bash scripts
- Proxmox API (pvesh/curl)
- SSH (OpenSSH)
- Docker CLI / docker-compose

**Secrets Management:**
- GitHub Secrets
- 1Password CLI
- SSH keys

**Monitoring:**
- Health check scripts (curl-based)
- GitHub Actions logs
- Future: Prometheus/Grafana integration

### Deployment Flow

**Standard Deployment:**
1. Developer pushes code to `main` branch in `services/my-service/`
2. GitHub Actions triggers via path filter
3. Self-hosted runner picks up job
4. Runner checks out code
5. Runner executes `services/my-service/deploy.sh`
6. Deployment script:
   - Connects to Proxmox/target host
   - Updates configuration
   - Restarts service/container
   - Runs health check
7. Health check validates service is running
8. Runner reports success/failure to GitHub
9. Deployment logs stored as artifact

**Failure Handling:**
1. Deployment script fails
2. Error captured in logs
3. GitHub commit status = failure
4. Notification sent (optional)
5. Logs available in GitHub Actions UI
6. State preserved for debugging
7. Manual investigation and fix

### Security Architecture

**Runner Security:**
- Dedicated LXC with minimal privileges
- Firewall rules: Allow outbound HTTPS (GitHub), SSH to targets
- No inbound connections required
- Regular security updates

**Credential Management:**
- Proxmox API token with read/write for specific resources
- SSH private key for service deployments
- Stored in GitHub Secrets
- Never logged or exposed
- Rotated quarterly

**Network Security:**
- Runner in homelab network (no public exposure)
- Proxmox API over HTTPS
- SSH key-based auth (no passwords)
- Services deployed with minimal privileges

## User Stories

### US1: Deploy New Service
**As a** DevOps engineer  
**I want to** add a new service to the repository  
**So that** it automatically deploys when I push changes

**Acceptance Criteria:**
- Copy `services/_template/` to `services/my-service/`
- Update `deploy.sh` with service-specific steps
- Configure target infrastructure
- Push to main → automatic deployment
- Deployment completes in < 5 minutes
- Service health check passes

### US2: Update Existing Service
**As a** developer  
**I want to** update a service configuration  
**So that** changes deploy automatically

**Acceptance Criteria:**
- Modify files in `services/my-service/`
- Commit and push to main
- GitHub Actions detects changes via path filter
- Only the modified service deploys
- Other services unaffected
- Deployment logs available

### US3: Troubleshoot Failed Deployment
**As a** DevOps engineer  
**I want to** view detailed logs when deployment fails  
**So that** I can quickly identify and fix the issue

**Acceptance Criteria:**
- Failed deployment shows red X in GitHub
- Click workflow run → see detailed logs
- Logs include error messages, stack traces, environment info
- Download logs as artifact
- State preserved for debugging
- Can manually re-trigger deployment

### US4: Roll Back Service
**As a** DevOps engineer  
**I want to** roll back to a previous version  
**So that** I can quickly recover from a bad deployment

**Acceptance Criteria:**
- Identify previous working commit/tag
- Re-run workflow on that commit
- Service reverts to previous version
- Health checks pass
- Documented procedure in runbook

### US5: Monitor Service Health
**As a** DevOps engineer  
**I want to** automated health checks  
**So that** I'm alerted when services fail

**Acceptance Criteria:**
- Daily scheduled health check workflow
- Tests all deployed services
- Reports failures as GitHub Issue
- Includes service name, error, timestamp
- Optional: Alert via Slack/email

## Implementation Phases

### Phase 1: Foundation (Week 1)
**Goal:** Basic deployment pipeline working

- [x] Create GitHub repository structure
- [ ] Set up self-hosted runner LXC on Proxmox
- [ ] Configure GitHub Actions workflow (basic)
- [ ] Create example service with Docker deployment
- [ ] Test end-to-end deployment
- [ ] Document setup process

**Deliverables:**
- Repository with initial structure
- Working self-hosted runner
- One service deploying successfully
- Basic documentation

### Phase 2: Core Features (Week 2-3)
**Goal:** Production-ready for multiple services

- [ ] Path-based triggering for individual services
- [ ] Health check scripts and workflow
- [ ] Proxmox API integration for LXC creation
- [ ] SSH-based deployment method
- [ ] Comprehensive logging
- [ ] Secrets management (1Password integration)

**Deliverables:**
- 3-5 services deployed via different methods
- Automated health monitoring
- Complete deployment runbooks

### Phase 3: Enhancement (Week 4+)
**Goal:** Advanced features and AWS support

- [ ] Rollback automation
- [ ] AWS EC2 deployment (proof of concept)
- [ ] Parallel deployments
- [ ] Deployment metrics/dashboard
- [ ] Slack/Discord notifications
- [ ] Service dependency management

**Deliverables:**
- AWS deployment example
- Notification system
- Enhanced monitoring

## Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Self-hosted runner failure | High | Low | Monitor runner health, auto-restart service |
| Proxmox API changes | Medium | Low | Pin API version, test before upgrades |
| Network connectivity issues | High | Medium | Retry logic, timeout handling, alerts |
| Deployment script bugs | Medium | Medium | Thorough testing, dry-run mode |
| Secrets exposure | Critical | Low | Never log secrets, regular audits |
| Concurrent deployment conflicts | Medium | Low | Queue system, deployment locks |

## Success Criteria

**MVP Success (Phase 1):**
- ✅ Self-hosted runner operational
- ✅ 1 service deploys automatically on push
- ✅ Deployment completes in < 5 minutes
- ✅ Logs captured and accessible

**Production Ready (Phase 2):**
- ✅ 5+ services deployed
- ✅ 95% deployment success rate
- ✅ Health monitoring operational
- ✅ Zero cost operation

**Full Feature (Phase 3):**
- ✅ AWS deployment working
- ✅ Rollback capability
- ✅ Automated notifications
- ✅ 10+ services managed

## Open Questions

1. **Q:** Which services deploy first?  
   **A:** Start with stateless web services, then add MCP servers

2. **Q:** Do we need staging environment?  
   **A:** Not initially - main branch = production, feature branches for testing

3. **Q:** How to handle database migrations?  
   **A:** Service-specific migration scripts in deploy.sh, run before app update

4. **Q:** Backup strategy?  
   **A:** Proxmox snapshots before deployment, service data backed up separately

5. **Q:** Load balancing for multiple instances?  
   **A:** Future consideration - current scope is single instance per service

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Proxmox API Documentation](https://pve.proxmox.com/wiki/Proxmox_VE_API)
- [Self-Hosted Runners Guide](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## Appendices

### Appendix A: Service Template Structure
See `services/_template/` directory

### Appendix B: Required GitHub Secrets
```
PROXMOX_API_URL=https://proxmox.local:8006/api2/json
PROXMOX_API_TOKEN=user@realm!tokenid=xxxxxxxx
SSH_PRIVATE_KEY=-----BEGIN OPENSSH PRIVATE KEY-----...
DOCKER_HOST_IP=192.168.1.x
```

### Appendix C: Self-Hosted Runner Setup Commands
```bash
# Create LXC on Proxmox
pct create 200 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname github-runner \
  --memory 4096 \
  --cores 2 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp

# Start and configure
pct start 200
pct enter 200

# Install dependencies
apt update && apt upgrade -y
apt install -y curl docker.io docker-compose

# Download and install GitHub runner
# (follow GitHub's instructions in repository Settings > Actions > Runners)
```

---

**Document Version:** 1.0  
**Last Updated:** November 16, 2025  
**Next Review:** December 1, 2025
