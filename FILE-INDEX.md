# Launch - File Index

Quick reference to all files in the project.

## 📚 Documentation Files

### Core Documentation
1. **[README.md](README.md)** - Project overview and getting started
2. **[PRD.md](PRD.md)** - Complete product requirements document
3. **[QUICKSTART.md](QUICKSTART.md)** - 30-minute setup guide
4. **[PROJECT-SUMMARY.md](PROJECT-SUMMARY.md)** - Complete project summary

### Detailed Guides
5. **[docs/SETUP.md](docs/SETUP.md)** - Comprehensive setup instructions
6. **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Problem resolution guide

## ⚙️ GitHub Actions Workflows

7. **[.github/workflows/deploy.yml](.github/workflows/deploy.yml)** - Main deployment workflow
8. **[.github/workflows/health-check.yml](.github/workflows/health-check.yml)** - Health monitoring workflow

## 🔧 Scripts

9. **[scripts/deploy-docker.sh](scripts/deploy-docker.sh)** - Docker deployment helper script

## 📦 Service Template

10. **[services/example-service/deploy.sh](services/example-service/deploy.sh)** - Deployment script template
11. **[services/example-service/health-check.sh](services/example-service/health-check.sh)** - Health check template
12. **[services/example-service/docker-compose.yml](services/example-service/docker-compose.yml)** - Docker Compose example
13. **[services/example-service/README.md](services/example-service/README.md)** - Service documentation template

## 📖 Reading Order

### For Quick Setup (30 minutes)
1. [QUICKSTART.md](QUICKSTART.md)
2. [services/example-service/deploy.sh](services/example-service/deploy.sh)
3. [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) (if needed)

### For Complete Understanding
1. [README.md](README.md) - Overview
2. [PRD.md](PRD.md) - Architecture and requirements
3. [docs/SETUP.md](docs/SETUP.md) - Detailed setup
4. [.github/workflows/deploy.yml](.github/workflows/deploy.yml) - Workflow details
5. [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Issue resolution

### For Service Development
1. [services/example-service/README.md](services/example-service/README.md) - Template overview
2. [services/example-service/deploy.sh](services/example-service/deploy.sh) - Deployment patterns
3. [services/example-service/health-check.sh](services/example-service/health-check.sh) - Health check patterns
4. [scripts/deploy-docker.sh](scripts/deploy-docker.sh) - Helper script reference

## 🎯 Quick Reference

### Setup Instructions
- Quick: [QUICKSTART.md](QUICKSTART.md)
- Detailed: [docs/SETUP.md](docs/SETUP.md)

### Troubleshooting
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

### Architecture
- [PRD.md](PRD.md) - See "Technical Architecture" section

### Workflow Details
- Deployment: [.github/workflows/deploy.yml](.github/workflows/deploy.yml)
- Health Checks: [.github/workflows/health-check.yml](.github/workflows/health-check.yml)

### Service Creation
- Template: [services/example-service/](services/example-service/)
- Instructions: [README.md](README.md) - See "Adding Services" section

## 📂 Directory Structure

```
launch/
├── .github/
│   └── workflows/
│       ├── deploy.yml
│       └── health-check.yml
├── docs/
│   ├── SETUP.md
│   └── TROUBLESHOOTING.md
├── scripts/
│   └── deploy-docker.sh
├── services/
│   └── example-service/
│       ├── deploy.sh
│       ├── health-check.sh
│       ├── docker-compose.yml
│       └── README.md
├── PRD.md
├── PROJECT-SUMMARY.md
├── QUICKSTART.md
├── README.md
└── FILE-INDEX.md (this file)
```

## 🚀 Common Tasks

### Deploy New Service
1. Copy template: `cp -r services/example-service services/my-service`
2. Edit: [services/example-service/deploy.sh](services/example-service/deploy.sh)
3. Push: `git add . && git commit -m "Add service" && git push`

### Troubleshoot Deployment
1. Check: GitHub Actions logs
2. Review: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
3. Test: `./deploy.sh` manually

### Modify Workflow
1. Edit: [.github/workflows/deploy.yml](.github/workflows/deploy.yml)
2. Test: Push to trigger
3. Debug: See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

**Total Files:** 13  
**Lines of Documentation:** ~8,500+  
**Lines of Code:** ~500
