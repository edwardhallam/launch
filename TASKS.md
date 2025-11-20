## 📋 Backlog

Tasks prioritized from top to bottom.

### Phase 1: Infrastructure as Code (The Foundation)

#### [US-013] Infrastructure as Code Foundation with Terraform
**Status**: In Progress
**Priority**: P0 (Critical)

**What:**
Initialize a Terraform setup within the repository (`/infrastructure`) that can provision both **AWS EC2 instances** and **Proxmox VMs/LXCs**. This includes setting up a remote state backend (e.g., AWS S3 or Cloudflare R2) to act as the "single source of truth".

**Why:**
- **Unified Tooling**: Terraform works seamlessly with both AWS and Proxmox providers.
- **Automated Provisioning**: Enables "one code check-in" infrastructure creation.
- **Registry/State**: Terraform state acts as the definitive registry of deployed resources.

**Acceptance Criteria:**
- Terraform project initialized in `infrastructure/`
- State backend configured (S3/R2) with locking
- AWS Provider configured
- Proxmox Provider configured
- CI/CD workflow to run `terraform plan` on PRs

**Estimate**: 3-4 hours

---

#### [US-014] Service Definition via Terraform Modules
**Status**: Ready
**Priority**: P0 (Critical)

**What:**
Create a reusable Terraform module (`modules/launch-service`) that abstracts the complexity of deploying to either AWS or Proxmox. Developers will define their service using standard Terraform code in the `infrastructure/` directory.

**Why:**
- **Standard Practice**: Uses industry-standard HCL syntax.
- **Abstraction**: Module handles provider-specific logic (AWS Security Groups vs Proxmox Firewall).
- **Cloudflare Integration**: Automatically manages DNS records based on `public = true` flag.

**Acceptance Criteria:**
- Module `modules/launch-service` created
- Supports `target` variable ("aws" or "proxmox")
- Supports `public` variable (toggles Cloudflare DNS)
- Validated with both AWS and Proxmox providers

**Estimate**: 4-5 hours

---

#### [US-015] Automated Runner Registration via Cloud-Init
**Status**: Ready
**Priority**: P0 (Critical)

**What:**
Develop a `cloud-init` user-data script template that Terraform will inject into every new VM. This script will automatically:
1. Install Docker and dependencies.
2. Use a GitHub Personal Access Token (PAT) to request a **Runner Registration Token**.
3. Download, configure, and start the GitHub Runner service.
4. Apply labels automatically (e.g., `aws`, `proxmox`, `service-name`).

**Why:**
- **Zero-Touch Provisioning**: VM boots, installs runner, and registers itself without manual SSH.
- **Immediate Availability**: The runner is ready to accept deployment jobs as soon as the VM comes online.

**Acceptance Criteria:**
- Cloud-init template created (`infrastructure/templates/user-data.sh.tftpl`)
- Terraform module updated to inject this script
- VM successfully registers as a runner upon boot
- Runner has correct labels applied

**Estimate**: 3-4 hours

---

### Phase 2: Application Deployment

#### [US-016] Application Deployment Workflow
**Status**: Ready
**Priority**: P0 (Critical)

**What:**
Create the GitHub Actions workflow (`.github/workflows/deploy-service.yml`) that connects the infrastructure to the application.
1. **Trigger**: Pushes to `services/**`.
2. **Routing**: Uses the `service-name` label (applied in US-015) to target the *specific* runner on the new VM.
3. **Action**: Checks out the code and runs `docker compose up` directly on that runner.

**Why:**
- **End-to-End Automation**: Completes the "One code check-in" goal.
- **Local Deployment**: Runner executes deployment commands locally on the VM.

**Acceptance Criteria:**
- Workflow created `.github/workflows/deploy-service.yml`
- Workflow triggers only on changes to specific service paths
- Workflow dynamically targets the correct runner using labels
- Deployment succeeds on the newly provisioned VM

**Estimate**: 2-3 hours

---

#### [US-017] Secret Injection via GitHub Secrets
**Status**: Ready
**Priority**: P1 (High)

**What:**
Update the deployment workflow to inject secrets directly into the `.env` file on the runner before starting the service.

**Why:**
- **Fully Automated**: Removes the need for manual SSH to configure environments.
- **Secure**: Secrets are encrypted in GitHub and never checked into the repo.

**Acceptance Criteria:**
- Workflow updated to accept secrets as inputs
- Step added to write secrets to `.env` file securely
- Service starts successfully with injected configuration

**Estimate**: 1-2 hours

---

### Phase 3: Verification & Testing

#### [US-018] Deploy Test Service (Homelab & AWS)
**Status**: Ready
**Priority**: P1 (High)

**What:**
Create a simple "Hello World" service (`services/test-service`) and deploy it to both environments.
1. Define `test-service-homelab` (Proxmox) and `test-service-aws` (AWS) in Terraform.
2. Push code to `services/test-service`.
3. Verify both runners pick up the job and deploy successfully.

**Why:**
- **End-to-End Validation**: Confirms the entire chain works before risking a real app.
- **Multi-Cloud Proof**: Proves the abstraction works for both targets.

**Acceptance Criteria:**
- `test-service` running on Proxmox LXC.
- `test-service` running on AWS EC2.
- Both accessible via HTTP.

**Estimate**: 2 hours

---

#### [US-019] Verify Update Workflow
**Status**: Ready
**Priority**: P1 (High)

**What:**
Make a visible change to `services/test-service/index.html` and push.
- Verify the workflow detects the change.
- Verify it redeploys *only* the test service.
- Verify the change is live.

**Why:**
- **Confidence**: Ensures we can ship updates reliably.
- **Idempotency**: Proves that re-running the deployment doesn't break things.

**Estimate**: 1 hour

---

### Phase 4: Production Services

#### [US-020] Deploy Librechat (Production)
**Status**: Ready
**Priority**: P1 (High)

**What:**
Use the new Terraform + GitHub Actions pipeline to deploy Librechat to AWS.
1. Define `librechat` in `infrastructure/main.tf` (using module).
2. Add Librechat code to `services/librechat`.
3. Push to main.

**Why:**
- **Validation**: Proves the entire platform works for a real-world production service.
- **Value**: Gets the chat service online for users.

**Acceptance Criteria:**
- Librechat accessible at `chat.spicyeddie.com` (via Cloudflare).
- SSL working.
- Service running on AWS EC2.

**Estimate**: 2 hours

---

## ✅ Completed

### [TASK-001] Reorganize project structure and implement task tracking
**Completed**: 2025-11-16
**Summary**: Successfully reorganized repository with proper folder structure.

### [TASK-000] Update documentation to reflect new priorities and architecture
**Completed**: 2025-11-18
**Summary**: Rewrote TASKS.md, updated PRD.md phases, and revised CLAUDE.md for multi-environment deployment.
