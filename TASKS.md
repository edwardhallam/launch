# Launch Platform - Task Tracker

**Last Updated**: 2025-11-18
**Current Phase**: Foundation (Phase 1)

---

## 🎯 Active Sprint

Tasks currently being worked on. **Only move tasks here when actively working on them.**

### In Progress
_No tasks in progress_

### Blocked
_No blocked tasks_

---

## 📋 Backlog

Tasks prioritized from top to bottom. Work from top down.

### Phase 1: Core Infrastructure & AWS Deployment

#### [US-001] Add Pull Request Validation Workflow
**Status**: Ready
**Priority**: P0 (Critical - Blocks development workflow)

**What:**
Create a GitHub Actions workflow that runs automated validation checks when pull requests are created or updated, before code is merged to `main`.

**Why:**
We need quality gates before deployments happen:
- Prevents broken deployments from reaching `main` branch
- Validates deployment scripts are executable and properly formatted
- Checks for common issues (missing files, syntax errors, etc.)
- Provides fast feedback to developers before merge
- Reduces failed deployments and rollback needs
- Establishes good CI/CD practices (test before deploy)
- Catches configuration errors early in the development cycle

**Acceptance Criteria:**
- New workflow file `.github/workflows/pr-validation.yml` created
- Triggers on pull request events (opened, synchronize, reopened)
- Validates changed services have required files (deploy.sh, health-check.sh, README.md)
- Checks that scripts are executable (chmod +x)
- Runs shellcheck on bash scripts for syntax/style issues
- Validates docker-compose.yml syntax if present
- Reports validation results as PR check status (pass/fail)
- Workflow runs on GitHub-hosted runner (fast, no infrastructure needed)
- Clear error messages when validation fails

**Estimate**: 2-3 hours
**Dependencies**: None

---

#### [US-002] Create Simple Test Service for End-to-End Workflow Validation
**Status**: Ready
**Priority**: P0 (Critical - Validates core workflow)

**What:**
Create a minimal HTTP service (nginx serving a static HTML page) in `services/test-service/` with all required deployment files (deploy.sh, health-check.sh, docker-compose.yml).

**Why:**
We need a simple, known-good service to:
- Validate the entire GitHub Actions workflow works end-to-end
- Test path-based triggering (changes to `services/test-service/` should trigger only that service)
- Verify deployment to LXC 110 via docker-compose works correctly
- Confirm health checks execute properly
- Establish a working baseline before deploying real services
- Provide a reference implementation for future services

**Acceptance Criteria:**
- Service directory created at `services/test-service/`
- docker-compose.yml defines nginx container with a simple HTML page
- deploy.sh successfully deploys to LXC 110 using docker-compose
- health-check.sh validates the service is responding to HTTP requests
- Service accessible on LXC 110's IP address (specific port TBD)
- All scripts are executable and follow project conventions

**Technical Approach:**
Use nginx:alpine image, mount a simple index.html, expose on a specific port, deploy using `scripts/deploy-docker.sh` pattern.

**Estimate**: 1-2 hours
**Dependencies**: US-001 (for PR validation)

---

#### [US-003] Deploy Test Service via GitHub Actions Workflow
**Status**: Ready
**Priority**: P0 (Critical - Validates automation)

**What:**
Push the test service to the `main` branch and validate that the GitHub Actions workflow automatically detects, deploys, and health-checks the service on LXC 110.

**Why:**
This validates the complete CI/CD pipeline:
- Confirms path-based triggering works (`services/test-service/**` changes trigger deployment)
- Verifies self-hosted runner (LXC 110) picks up and executes the job
- Tests deployment script execution in the GitHub Actions environment
- Validates health check runs post-deployment
- Ensures logs are captured and available in GitHub Actions UI
- Proves the foundational workflow before building more complex services
- Identifies any permission, networking, or configuration issues early

**Acceptance Criteria:**
- Push to `main` with test service triggers `.github/workflows/deploy.yml`
- Workflow runs on self-hosted runner (LXC 110)
- Deployment completes successfully (green checkmark in GitHub)
- Service is running on LXC 110 (docker ps shows container)
- Health check passes
- Service is accessible via HTTP on LXC 110's IP
- Deployment logs are available in GitHub Actions UI
- No other services are affected (isolated deployment)

**Technical Approach:**
Commit and push test service files, monitor workflow execution in GitHub Actions tab, verify deployment on LXC 110 via SSH.

**Estimate**: 1 hour (assuming workflow is already configured)
**Dependencies**: US-002

---

#### [US-004] Update Test Service to Validate Change Detection
**Status**: Ready
**Priority**: P0 (Critical - Validates update flow)

**What:**
Make a simple change to the test service (e.g., modify the HTML content) and push to `main` to verify that the workflow detects the change and redeploys only that service.

**Why:**
This validates the update/redeployment flow:
- Confirms the workflow correctly detects changes to existing services
- Verifies that redeployment overwrites the previous version correctly
- Tests that docker-compose handles updates properly (pulls new config, restarts containers)
- Ensures health checks still pass after updates
- Proves the system can handle iterative development cycles
- Validates that only the changed service redeploys (other services remain untouched)

**Acceptance Criteria:**
- Modify test service (e.g., change HTML content or add new file)
- Push to `main` triggers deployment workflow
- Only `test-service` is deployed (not other services if any exist)
- Updated content is visible in the running service
- Health check passes with new version
- Previous container is stopped/removed, new one is running
- Deployment completes successfully with logs available

**Technical Approach:**
Edit `services/test-service/` files, commit, push, observe workflow execution and verify changes are live.

**Estimate**: 30 minutes
**Dependencies**: US-003

---

#### [US-005] Configure AWS Runner and Credentials
**Status**: Ready
**Priority**: P0 (Critical - Enables AWS deployments)

**What:**
Install GitHub Actions runner on the existing EC2 instance and configure AWS-related GitHub Secrets for deployment workflows.

**Why:**
We need the EC2 instance to act as both runner and deployment host (matching the LXC 110 pattern):
- Enables AWS deployments using the same architectural pattern as homelab
- Allows workflow routing via runner labels (`runs-on: [self-hosted, aws]` vs `runs-on: [self-hosted, homelab]`)
- Provides environment isolation (homelab failures don't affect AWS deployments)
- Scales cleanly to additional cloud providers in the future
- Zero additional cost (uses existing EC2 instance)
- Runner has local access to Docker daemon on same machine (fast, simple deployments)

**Acceptance Criteria:**
- GitHub Actions runner installed on existing EC2 instance
- Runner registered with repository and showing online
- Runner labeled with `aws` label (for workflow routing)
- Runner configured as service (starts on reboot)
- Docker and docker-compose installed on EC2 instance
- Required GitHub Secrets added: `AWS_REGION`, any AWS-specific configs
- EC2 security group allows HTTP/HTTPS inbound (for deployed services)
- Runner user has docker group permissions
- Can execute `docker ps` successfully on EC2

**Technical Approach:**
SSH to EC2, install runner following GitHub's instructions, configure as systemd service, label appropriately, install Docker.

**Estimate**: 2-3 hours
**Dependencies**: US-004 (homelab workflow validated first)

---

#### [US-006] Create Librechat Service with Deployment Configuration
**Status**: Ready
**Priority**: P0 (Critical - Production service)

**What:**
Create a new service directory `services/librechat/` with deployment scripts, docker-compose configuration, and health checks that will deploy to the EC2 runner/host.

**Why:**
This establishes the production AWS service you want running ASAP:
- Provides the service structure that will run Librechat on AWS
- Uses generic docker-compose deployment pattern (works for any containerized service)
- Validates that the AWS runner can deploy containerized services
- Proves the multi-cloud workflow routing works (homelab vs AWS)
- Gets Librechat live in production quickly through proper CI/CD
- Creates a reusable pattern for future AWS services (methodology is generic even though service is specific)

**Acceptance Criteria:**
- Service directory created at `services/librechat/`
- docker-compose.yml configured for Librechat (ports, volumes, environment variables)
- deploy.sh configured to deploy via docker-compose on AWS runner
- health-check.sh validates Librechat is responding correctly
- README.md documents the service, ports, and AWS-specific configuration
- Workflow configured to route this service to AWS runner (via runner labels)
- All scripts executable and follow project conventions
- Service configuration uses environment variables/secrets (no hardcoded credentials)

**Technical Approach:**
Create service directory structure, configure docker-compose for Librechat containers, set up deployment script to use AWS runner label, define health check endpoint.

**Estimate**: 2-3 hours
**Dependencies**: US-005

---

#### [US-007] Configure Secrets for Librechat Deployment
**Status**: Ready
**Priority**: P0 (Critical - Blocks Librechat deployment)

**What:**
Add required GitHub Secrets for Librechat deployment (database credentials, API keys, environment-specific configuration).

**Why:**
Librechat needs secure credential storage:
- Database passwords, API keys, and other secrets cannot be in the repository
- GitHub Secrets provides secure, encrypted storage accessible to workflows
- Secrets must be available to the AWS runner during deployment
- Environment variables need to be injected into docker-compose at runtime
- Follows security best practices (no hardcoded credentials)
- Enables the deployment to work without manual configuration on EC2

**Acceptance Criteria:**
- All required Librechat secrets identified and documented
- Secrets added to GitHub repository settings
- Secrets are environment-specific (prefixed with `AWS_` or similar if needed)
- deploy.sh for Librechat references secrets as environment variables
- docker-compose.yml uses environment variable substitution
- Deployment works with secrets properly injected
- No secrets logged or exposed in GitHub Actions output
- README.md documents which secrets are required

**Technical Approach:**
Identify required secrets, add to GitHub Secrets, update docker-compose.yml and deploy.sh to use environment variables, test deployment.

**Estimate**: 1-2 hours
**Dependencies**: US-006

---

#### [US-008] Deploy Librechat to AWS via GitHub Actions Workflow
**Status**: Ready
**Priority**: P0 (Critical - Production deployment)

**What:**
Push the Librechat service to `main` branch and validate that the GitHub Actions workflow routes the deployment to the AWS runner (EC2) and successfully deploys the service.

**Why:**
This proves the multi-cloud deployment capability:
- Validates workflow runner label routing works (`runs-on: [self-hosted, aws]`)
- Confirms AWS runner picks up and executes the deployment job
- Tests that Librechat deploys correctly to EC2 via docker-compose
- Verifies health checks pass on AWS infrastructure
- Gets your production service live and accessible
- Proves the deployment pattern works across different infrastructure (homelab + AWS)
- Establishes confidence in the CI/CD pipeline for production workloads

**Acceptance Criteria:**
- Push to `main` with Librechat service triggers deployment workflow
- Workflow correctly routes to AWS runner (not LXC 110)
- Deployment completes successfully on EC2
- Librechat containers are running on EC2 (docker ps shows them)
- Health check passes
- Service is accessible via EC2 public IP/hostname
- Deployment logs available in GitHub Actions UI
- No interference with homelab services (test-service still running on LXC 110)

**Technical Approach:**
Commit and push Librechat files, monitor workflow execution, verify runner routing, confirm deployment on EC2 via SSH/web browser.

**Estimate**: 1-2 hours
**Dependencies**: US-007

---

#### [US-009] Configure Workflow to Support Multi-Environment Routing
**Status**: Ready
**Priority**: P1 (High - Enables scalability)

**What:**
Update `.github/workflows/deploy.yml` to support routing service deployments to different runners based on service configuration (homelab services go to LXC 110, AWS services go to EC2 runner).

**Why:**
We need intelligent routing so the workflow knows where to deploy each service:
- Different services target different infrastructure (test-service → homelab, librechat → AWS)
- Workflow must dynamically determine which runner to use per service
- Enables the multi-cloud architecture we're building toward
- Allows each service to declare its target environment independently
- Supports future expansion (additional cloud providers, multiple AWS regions, etc.)
- Makes the deployment workflow truly infrastructure-agnostic

**Acceptance Criteria:**
- Services can specify target environment (via file like `target.txt`, environment variable, or naming convention)
- Workflow reads service target configuration
- Workflow uses appropriate runner labels (`[self-hosted, homelab]` or `[self-hosted, aws]`)
- test-service deploys to LXC 110 (homelab runner)
- librechat deploys to EC2 (AWS runner)
- Each service deploys to its correct target infrastructure
- Workflow supports adding new environments/runners in the future

**Technical Approach:**
Add target configuration to service directories, update workflow to read and route based on target, use matrix strategy or conditional logic for runner selection.

**Estimate**: 2-3 hours
**Dependencies**: US-008 (validate both services work before adding routing logic)

---

### Phase 1: Production Readiness

#### [US-010] Document Service Creation Process and Best Practices
**Status**: Ready
**Priority**: P1 (High - Enables future development)

**What:**
Create comprehensive documentation for adding new services to the platform, including step-by-step guides, examples, and troubleshooting tips.

**Why:**
Future service additions need clear guidance:
- You'll be adding more services over time
- Documentation reduces friction when creating new services
- Captures lessons learned from test-service and Librechat deployments
- Provides templates and examples that work
- Helps avoid common pitfalls
- Makes the platform self-service (less trial and error)
- Useful reference when working with AI assistants on future services

**Acceptance Criteria:**
- Step-by-step guide for creating a new service
- Example service templates for common patterns (web app, API, database)
- Documentation of required files and their purposes
- Explanation of environment targeting (homelab vs AWS)
- Secrets management guidance
- Health check pattern examples
- Troubleshooting common deployment issues
- Quick reference checklist for new services

**Technical Approach:**
Create docs/ADDING-SERVICES.md with comprehensive guide, update example-service template, document patterns from real deployments.

**Estimate**: 3-4 hours
**Dependencies**: US-009 (after both services deployed and working)

---

#### [US-011] Configure Cloudflare Tunnel for Librechat
**Status**: Ready
**Priority**: P1 (High - Production access)

**What:**
Set up Cloudflare Tunnel to securely expose Librechat running on EC2 and map it to chat.spicyeddie.com.

**Why:**
Production web services need secure, reliable public access:
- Cloudflare Tunnel provides secure ingress without opening EC2 ports
- Enables HTTPS/SSL automatically through Cloudflare
- Domain chat.spicyeddie.com provides professional, memorable URL
- Cloudflare provides DDoS protection and CDN benefits
- No need to manage security groups for HTTP/HTTPS on EC2
- Health checks can validate against production domain

**Acceptance Criteria:**
- Cloudflare Tunnel installed and configured on EC2 instance
- Tunnel connected to Cloudflare account
- DNS record for chat.spicyeddie.com points to tunnel
- Librechat accessible via https://chat.spicyeddie.com
- SSL/TLS working properly (Cloudflare-managed certificate)
- Tunnel configured to start on boot (systemd service)
- Health check updated to validate against chat.spicyeddie.com
- Tunnel configuration documented in service README

**Technical Approach:**
Install cloudflared on EC2, authenticate with Cloudflare, create tunnel, configure DNS, set up systemd service, test accessibility.

**Estimate**: 2-3 hours
**Dependencies**: US-008 (Librechat must be deployed first)

---

#### [US-012] Test Librechat Update via Pull Request
**Status**: Ready
**Priority**: P1 (High - Validates production workflow)

**What:**
Make a configuration change to Librechat (e.g., update environment variable or docker-compose setting) via pull request, validate PR checks pass, merge, and verify the service updates correctly on AWS.

**Why:**
Validates the complete production workflow:
- Ensures PR validation works for AWS services
- Tests that Librechat can be updated without downtime or issues
- Verifies docker-compose handles updates correctly (container recreation)
- Proves the development cycle works for production services
- Validates health checks still pass after updates
- Provides confidence in making future changes to Librechat

**Acceptance Criteria:**
- Create feature branch with Librechat config change
- Open PR, validation runs and passes
- Merge PR to main
- Deployment workflow triggers and routes to AWS runner
- Librechat updates successfully on EC2
- Service remains accessible during update (or minimal downtime documented)
- Health check passes with updated configuration
- chat.spicyeddie.com reflects the changes

**Technical Approach:**
Branch, modify docker-compose.yml or environment config, PR, merge, monitor deployment, verify update.

**Estimate**: 1 hour
**Dependencies**: US-011 (Cloudflare Tunnel must be working)

---

## ✅ Completed

Tasks marked as done. **Most recent at the top.**

### [TASK-001] Reorganize project structure and implement task tracking
**Completed**: 2025-11-16

**Summary**: Successfully reorganized repository with proper folder structure

**Changes Made**:
- Created TASKS.md for task tracking
- Created directory structure: .github/workflows/, services/, scripts/, docs/
- Moved workflow files to .github/workflows/
- Moved documentation to docs/
- Created services/example-service/ template with deploy.sh, health-check.sh, docker-compose.yml
- Moved deploy-docker.sh to scripts/
- Updated all file references in README.md and CLAUDE.md

---

### [TASK-000] Update documentation to reflect new priorities and architecture
**Completed**: 2025-11-18

**Summary**: Rewrote TASKS.md, updated PRD.md phases, and revised CLAUDE.md for multi-environment deployment

**Changes Made**:
- Rewrote TASKS.md with user stories including detailed "What" and "Why" sections
- Updated PRD.md to prioritize AWS deployment in Phase 1
- Updated CLAUDE.md with correct runner IDs (LXC 110, EC2)
- Documented multi-environment architecture (homelab + AWS)
- Updated all references to reflect current state

---

## 📝 Task Management Guide

### For Claude Code

When working with this file:

1. **Starting a task**: Move from Backlog to "Active Sprint > In Progress"
2. **Completing a task**: Move to "Completed" section with completion date
3. **Blocking a task**: Move to "Active Sprint > Blocked" with reason
4. **Reprioritizing**: Reorder tasks in Backlog section
5. **Adding tasks**: Add to appropriate Backlog section with next sequential ID

### Task ID Format

- User Stories: `[US-XXX]` - Three-digit sequential number
- Internal Tasks: `[TASK-XXX]` - Three-digit sequential number
- Never reuse IDs
- Include ID in commit messages when relevant

### Status Values

- **Ready**: Defined and ready to start
- **In Progress**: Actively being worked on
- **Blocked**: Cannot proceed (document blocker)
- **Completed**: Finished and verified

### Priority Guidelines

- **P0 (Critical)**: Blocking other work, must complete for system to function
- **P1 (High)**: Important for production readiness, near-term priority
- **P2 (Medium)**: Valuable features, medium-term goals
- **P3 (Low)**: Nice-to-have, future enhancements

---

## 🔄 Architecture Overview

### Current Infrastructure

**Homelab Runner (LXC 110)**:
- Ubuntu LXC on Proxmox
- GitHub Actions runner with label: `homelab`
- Docker + docker-compose installed
- Serves as both runner and deployment host for homelab services
- Deploys: test-service, other homelab services

**AWS Runner (EC2)**:
- EC2 instance in AWS
- GitHub Actions runner with label: `aws`
- Docker + docker-compose installed
- Serves as both runner and deployment host for AWS services
- Deploys: Librechat, other AWS services

**Workflow Routing**:
- Services declare target environment
- Workflow routes to appropriate runner based on target
- Each runner deploys locally (no cross-environment SSH)

---

**Note**: This file is designed for both human and Claude Code usage. Keep formatting consistent for easy parsing.
