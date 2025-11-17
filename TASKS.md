# Launch Platform - Task Tracker

**Last Updated**: 2025-11-16
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

Tasks prioritized from top to bottom. **Drag tasks to reorder priority.**

### High Priority

- [TASK-002] Set up self-hosted GitHub Actions runner on Proxmox LXC
  - **Status**: Ready
  - **Phase**: 1 - Foundation
  - **Estimate**: 2-3 hours
  - **Prerequisites**: Proxmox infrastructure access
  - **Acceptance Criteria**:
    - Runner LXC (ID 200) created and configured
    - Runner registered with GitHub repository
    - Runner can execute test workflow
  - **References**: docs/QUICKSTART.md, docs/SETUP.md

- [TASK-003] Deploy first test service using Docker method
  - **Status**: Ready
  - **Phase**: 1 - Foundation
  - **Estimate**: 1 hour
  - **Prerequisites**: TASK-002 completed
  - **Acceptance Criteria**:
    - Service deploys successfully via workflow
    - Health check passes
    - Service accessible on network
  - **References**: services/example-service/

### Medium Priority

- [TASK-004] Implement LXC creation deployment method
  - **Status**: Not Started
  - **Phase**: 2 - LXC Support
  - **Estimate**: 4-6 hours
  - **Prerequisites**: TASK-003 completed
  - **Acceptance Criteria**:
    - `scripts/deploy-lxc.sh` created
    - Can create LXC via Proxmox API
    - Can provision software inside LXC
    - Example service using LXC method works
  - **References**: docs/PRD.md (FR4)

- [TASK-005] Implement VM deployment method
  - **Status**: Not Started
  - **Phase**: 2 - VM Support
  - **Estimate**: 3-4 hours
  - **Prerequisites**: TASK-003 completed
  - **Acceptance Criteria**:
    - `scripts/deploy-vm.sh` created
    - Can deploy to existing VMs via SSH
    - Example service using VM method works
  - **References**: docs/PRD.md (FR4)

- [TASK-006] Add rollback automation
  - **Status**: Not Started
  - **Phase**: 2 - Enhanced Automation
  - **Estimate**: 4-5 hours
  - **Prerequisites**: TASK-003 completed
  - **Acceptance Criteria**:
    - Can trigger rollback to previous deployment
    - Workflow action or manual trigger available
    - State tracking for deployments
  - **References**: docs/PRD.md (FR10)

### Low Priority

- [TASK-007] Add notification integrations (Slack/Discord)
  - **Status**: Not Started
  - **Phase**: 2 - Enhancements
  - **Estimate**: 2-3 hours
  - **Prerequisites**: TASK-003 completed
  - **Acceptance Criteria**:
    - Slack webhook integration working
    - Discord webhook integration working
    - Configurable per-service
  - **References**: deploy.yml:160

- [TASK-008] Implement AWS deployment targets
  - **Status**: Not Started
  - **Phase**: 3 - Multi-Cloud
  - **Estimate**: 8-10 hours
  - **Prerequisites**: All Phase 2 tasks completed
  - **Acceptance Criteria**:
    - Can deploy to AWS EC2
    - Can deploy to AWS ECS
    - Configuration switch between Proxmox/AWS
  - **References**: docs/PRD.md (Phase 3)

### Backlog (Unprioritized)

- [TASK-009] Add deployment metrics and monitoring dashboard
- [TASK-010] Implement secrets rotation automation
- [TASK-011] Add multi-environment support (dev/staging/prod)
- [TASK-012] Create web UI for deployment management
- [TASK-013] Add automated testing for deployment scripts

---

## ✅ Completed

Tasks marked as done. **Most recent at the top.**

- [TASK-001] Reorganize project structure and implement task tracking
  - **Completed**: 2025-11-16
  - **Summary**: Successfully reorganized repository with proper folder structure
  - **Changes Made**:
    - Created TASKS.md for task tracking
    - Created directory structure: .github/workflows/, services/, scripts/, docs/
    - Moved workflow files to .github/workflows/
    - Moved documentation to docs/
    - Created services/example-service/ template with deploy.sh, health-check.sh, docker-compose.yml
    - Moved deploy-docker.sh to scripts/
    - Updated all file references in README.md and CLAUDE.md

---

## 📝 Task Management Guide

### For Claude Code

When working with this file:

1. **Starting a task**: Move from Backlog to "Active Sprint > In Progress"
2. **Completing a task**: Move to "Completed" section with completion date
3. **Blocking a task**: Move to "Active Sprint > Blocked" with reason
4. **Reprioritizing**: Reorder tasks in Backlog section
5. **Adding tasks**: Add to appropriate Backlog priority section

### Task ID Format

- `[TASK-XXX]` - Three-digit sequential number
- Never reuse task IDs
- Include task ID in commit messages when relevant

### Status Values

- **Ready**: Defined and ready to start
- **In Progress**: Actively being worked on
- **Blocked**: Cannot proceed (document blocker)
- **Completed**: Finished and verified
- **Not Started**: Defined but not ready

### Priority Guidelines

- **High**: Blocking other work, critical path, Phase 1 goals
- **Medium**: Important but not blocking, Phase 2 features
- **Low**: Nice-to-have, Phase 3+, enhancements

---

## 🔄 Quick Reference

```bash
# View this file
cat TASKS.md

# Update task status (Claude Code will edit this file)
# Example: Moving task to in-progress
# 1. Find task in Backlog
# 2. Move to "Active Sprint > In Progress"
# 3. Update "Started" date
# 4. Update "Last Updated" at top of file

# Add new task
# 1. Choose appropriate Backlog priority section
# 2. Assign next sequential TASK-XXX ID
# 3. Fill in all fields
# 4. Update "Last Updated" at top of file
```

---

**Note**: This file is designed for both human and Claude Code usage. Keep formatting consistent for easy parsing.
