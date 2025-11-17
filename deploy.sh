#!/bin/bash
#
# Example deployment script for [SERVICE_NAME]
# 
# Replace this with your actual deployment logic
# Choose one of the deployment methods below or create your own
#
# Environment variables available:
#   PROXMOX_API_URL - Proxmox API endpoint
#   PROXMOX_API_TOKEN - Proxmox API authentication token
#   DOCKER_HOST_IP - IP of Docker host LXC
#   SERVICE_NAME - Name of this service
#

set -e  # Exit on error

echo "🚀 Deploying ${SERVICE_NAME}..."

# ============================================================================
# DEPLOYMENT METHOD 1: Docker Compose
# ============================================================================
#
# Use this if deploying to existing Docker host LXC
#
# Uncomment to use:
# ../../scripts/deploy-docker.sh

# ============================================================================
# DEPLOYMENT METHOD 2: Create New LXC
# ============================================================================
#
# Use this to create a new LXC container on Proxmox
#
# Uncomment to use:
# ../../scripts/deploy-lxc.sh

# ============================================================================
# DEPLOYMENT METHOD 3: Deploy to Existing VM
# ============================================================================
#
# Use this to deploy to an existing VM via SSH
#
# Uncomment to use:
# ../../scripts/deploy-vm.sh

# ============================================================================
# CUSTOM DEPLOYMENT
# ============================================================================
#
# Or write your own deployment logic here:

echo "⚠️  This is a template deployment script"
echo "Please customize this file for your service"
echo ""
echo "Steps to customize:"
echo "1. Choose a deployment method above (uncomment one)"
echo "2. Or write custom deployment logic"
echo "3. Test deployment locally first"
echo "4. Update health-check.sh to validate your service"
echo ""
echo "For now, this is a no-op deployment (for template purposes)"

# Example custom deployment:
# echo "Connecting to target..."
# ssh user@host "bash -s" < install.sh
# echo "Deployment complete!"

exit 0
