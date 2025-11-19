#!/bin/bash
#
# Deploy Service to VM/LXC (Direct Install)
#
# This script deploys a service directly to a VM or LXC container
# without using Docker. It assumes the target system has been
# provisioned with the necessary dependencies (Node, Python, etc.)
# and a 'deploy' user.
#
# Environment variables:
#   VM_HOST_IP     - IP address of target VM/LXC
#   SERVICE_NAME   - Name of the service being deployed
#   SSH_USER       - SSH user (default: deploy)
#   INSTALL_DIR    - Base directory for services (default: /opt/services)
#
# Usage: ./deploy-vm.sh

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate environment
if [ -z "${VM_HOST_IP:-}" ]; then
    log_error "VM_HOST_IP environment variable not set"
    exit 1
fi

if [ -z "${SERVICE_NAME:-}" ]; then
    log_error "SERVICE_NAME environment variable not set"
    exit 1
fi

# Defaults
SSH_USER="${SSH_USER:-deploy}"
BASE_DIR="${INSTALL_DIR:-/opt/services}"
SERVICE_DIR="${BASE_DIR}/${SERVICE_NAME}"
TARGET_HOST="${SSH_USER}@${VM_HOST_IP}"

log_info "Deploying ${SERVICE_NAME} to ${TARGET_HOST}"

# Check connectivity
log_info "Checking connectivity..."
if ! ssh -o ConnectTimeout=5 "${TARGET_HOST}" "echo 'Connected'" &>/dev/null; then
    log_error "Cannot connect to ${TARGET_HOST}"
    log_error "Possible reasons:"
    log_error "1. Network connectivity issues"
    log_error "2. SSH key not authorized for user '${SSH_USER}'"
    log_error "3. Host key verification failed"
    exit 1
fi

# Create service directory
log_info "Ensuring service directory exists: ${SERVICE_DIR}"
ssh "${TARGET_HOST}" "mkdir -p ${SERVICE_DIR}"

# Transfer files
# We use rsync if available, otherwise scp
log_info "Transferring files..."

# Exclude common junk
EXCLUDES="--exclude .git --exclude node_modules --exclude venv --exclude __pycache__ --exclude .env"

if command -v rsync &>/dev/null; then
    # Use rsync for efficiency
    rsync -avz -e ssh $EXCLUDES ./ "${TARGET_HOST}:${SERVICE_DIR}/"
else
    # Fallback to SCP (less efficient, copies everything)
    log_warn "rsync not found, falling back to scp"
    scp -r . "${TARGET_HOST}:${SERVICE_DIR}/"
fi

# Install Dependencies
log_info "Installing dependencies..."

# Check for package.json (Node.js)
if [ -f "package.json" ]; then
    log_info "Detected Node.js project. Running npm install..."
    ssh "${TARGET_HOST}" "cd ${SERVICE_DIR} && npm install --production"
fi

# Check for requirements.txt (Python)
if [ -f "requirements.txt" ]; then
    log_info "Detected Python project. Installing requirements..."
    # Check if venv exists, create if not
    ssh "${TARGET_HOST}" "cd ${SERVICE_DIR} && [ ! -d venv ] && python3 -m venv venv || true"
    ssh "${TARGET_HOST}" "cd ${SERVICE_DIR} && source venv/bin/activate && pip install -r requirements.txt"
fi

# Restart Service
# This relies on sudoers configuration allowing 'systemctl restart SERVICE_NAME'
log_info "Restarting service..."
if ssh "${TARGET_HOST}" "sudo systemctl restart ${SERVICE_NAME}"; then
    log_info "✅ Service restarted successfully"
else
    log_error "❌ Failed to restart service"
    log_error "Check sudo permissions for user '${SSH_USER}'"
    exit 1
fi

# Check Status
log_info "Checking service status..."
if ssh "${TARGET_HOST}" "systemctl is-active ${SERVICE_NAME}" &>/dev/null; then
    log_info "✅ Service is active"
else
    log_error "❌ Service is not active"
    ssh "${TARGET_HOST}" "sudo systemctl status ${SERVICE_NAME} --no-pager"
    exit 1
fi

log_info "✅ Deployment completed successfully"
