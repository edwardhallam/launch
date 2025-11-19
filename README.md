# Launch 🚀

**Service-Owned Infrastructure for Homelab & Cloud**

Launch is a "One Code Check-in" platform. You define your service and its infrastructure in code, push to GitHub, and the platform handles the rest: provisioning VMs, bootstrapping runners, and deploying your application.

## �️ Architecture

```mermaid
graph TD
    User[Developer] -->|Push Code + TF| GitHub[GitHub Repo]
    GitHub -->|Trigger| ActionInfra[Action: Infra Provision]
    
    subgraph "Control Plane"
        ActionInfra -->|Terraform Apply| AWS[AWS API]
        ActionInfra -->|Terraform Apply| Proxmox[Proxmox API]
        ActionInfra -->|Update DNS| Cloudflare[Cloudflare API]
    end
    
    subgraph "Data Plane"
        AWS -->|Create| EC2[EC2 Instance]
        Proxmox -->|Create| LXC[LXC Container]
        
        EC2 -->|Cloud-Init| Bootstrap[Bootstrap Runner]
        LXC -->|Cloud-Init| Bootstrap
    end
    
    Bootstrap -->|Register| GitHub
    
    GitHub -->|Trigger| ActionDeploy[Action: App Deploy]
    ActionDeploy -->|Run Job| EC2
    ActionDeploy -->|Run Job| LXC
    
    EC2 -->|Docker Up| App[Running Service]
```

## 📚 Documentation

*   **[PRD](docs/PRD.md)**: Detailed architecture and requirements.
*   **[Setup Guide](docs/SETUP.md)**: How to bootstrap the platform initially.
*   **[Troubleshooting](docs/TROUBLESHOOTING.md)**: Common issues and fixes.

---
*Built with Terraform, GitHub Actions, Proxmox, and AWS.*
