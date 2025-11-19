#!/bin/bash
#
# Deploy Docker Compose service to Docker host
# 
# Environment variables:
#   DOCKER_HOST_IP - IP address of Docker host LXC
#   SERVICE_NAME   - Name of the service being deployed
#   SSH_USER       - SSH user (default: deploy)
#   INSTALL_DIR    - Base directory for services (default: /opt/services)
#
# Usage: ./deploy-docker.sh

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
if [ -z "${DOCKER_HOST_IP:-}" ]; then
    log_error "DOCKER_HOST_IP environment variable not set"
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
DOCKER_HOST="${SSH_USER}@${DOCKER_HOST_IP}"

log_info "Deploying ${SERVICE_NAME} to ${DOCKER_HOST}"

# Check connectivity and Host Key
log_info "Checking connectivity..."

# We do NOT use StrictHostKeyChecking=no anymore.
# The runner must have the host key in known_hosts.
if ! ssh -o ConnectTimeout=5 "${DOCKER_HOST}" "echo 'Connected'" &>/dev/null; then
    log_error "Cannot connect to ${DOCKER_HOST}"
    log_error "Possible reasons:"
    log_error "1. Network connectivity issues"
    log_error "2. SSH key not authorized for user '${SSH_USER}'"
    log_error "3. Host key verification failed (Host key not in known_hosts)"
    exit 1
fi

# Create service directory
log_info "Ensuring service directory exists: ${SERVICE_DIR}"
ssh "${DOCKER_HOST}" "mkdir -p ${SERVICE_DIR}"

# Copy docker-compose.yml and related files
log_info "Copying service files..."
if [ -f "docker-compose.yml" ]; then
    scp docker-compose.yml "${DOCKER_HOST}:${SERVICE_DIR}/"
else
    log_error "docker-compose.yml not found in current directory"
    exit 1
fi

# Copy config directory if it exists
if [ -d "config" ]; then
    log_info "Copying config directory..."
    scp -r config "${DOCKER_HOST}:${SERVICE_DIR}/"
fi

# Copy .env file if it exists
if [ -f ".env" ]; then
    log_info "Copying .env file..."
    scp .env "${DOCKER_HOST}:${SERVICE_DIR}/"
fi

# Pull latest images
log_info "Pulling Docker images..."
ssh "${DOCKER_HOST}" "cd ${SERVICE_DIR} && docker-compose pull"

# Stop existing containers
log_info "Stopping existing containers..."
ssh "${DOCKER_HOST}" "cd ${SERVICE_DIR} && docker-compose down || true"

# Start containers
log_info "Starting containers..."
ssh "${DOCKER_HOST}" "cd ${SERVICE_DIR} && docker-compose up -d"

# Wait for containers to start
log_info "Waiting for containers to start..."
sleep 5

# Check container status
log_info "Checking container status..."
CONTAINER_STATUS=$(ssh "${DOCKER_HOST}" "cd ${SERVICE_DIR} && docker-compose ps --format json" | jq -r '.[].State')

if echo "$CONTAINER_STATUS" | grep -q "running"; then
    log_info "✅ Containers are running"
else
    log_error "❌ Containers failed to start"
    log_error "Container status: $CONTAINER_STATUS"
    
    # Show logs
    log_error "Container logs:"
    ssh "${DOCKER_HOST}" "cd ${SERVICE_DIR} && docker-compose logs --tail=50"
    exit 1
fi

# Show running containers
log_info "Running containers:"
ssh "${DOCKER_HOST}" "cd ${SERVICE_DIR} && docker-compose ps"

log_info "✅ Deployment completed successfully"
