#!/bin/bash
#
# Health check for [SERVICE_NAME]
#
# This script should validate that the service is running correctly
# Exit 0 for success, non-zero for failure
#

set -e

echo "🏥 Health check for ${SERVICE_NAME:-example-service}..."

# ============================================================================
# EXAMPLE 1: HTTP Health Check
# ============================================================================
# 
# Use this for web services that expose HTTP endpoints
# Uncomment to use:
#
# SERVICE_URL="http://192.168.1.20:8080/health"
# 
# if curl -f -s -o /dev/null -w "%{http_code}" "$SERVICE_URL" | grep -q "200"; then
#     echo "✅ HTTP health check passed"
#     exit 0
# else
#     echo "❌ HTTP health check failed"
#     exit 1
# fi

# ============================================================================
# EXAMPLE 2: Docker Container Check
# ============================================================================
#
# Use this for services running in Docker
# Uncomment to use:
#
# DOCKER_HOST="root@${DOCKER_HOST_IP}"
# CONTAINER_NAME="my-service"
#
# STATUS=$(ssh "$DOCKER_HOST" "docker inspect -f '{{.State.Status}}' $CONTAINER_NAME" 2>/dev/null || echo "not found")
#
# if [ "$STATUS" = "running" ]; then
#     echo "✅ Container is running"
#     exit 0
# else
#     echo "❌ Container is $STATUS"
#     exit 1
# fi

# ============================================================================
# EXAMPLE 3: Port Check
# ============================================================================
#
# Use this to check if a service is listening on a port
# Uncomment to use:
#
# SERVICE_HOST="192.168.1.20"
# SERVICE_PORT="8080"
#
# if nc -z -w5 "$SERVICE_HOST" "$SERVICE_PORT"; then
#     echo "✅ Port $SERVICE_PORT is open"
#     exit 0
# else
#     echo "❌ Port $SERVICE_PORT is not accessible"
#     exit 1
# fi

# ============================================================================
# EXAMPLE 4: Process Check (via SSH)
# ============================================================================
#
# Use this to check if a process is running on a VM/LXC
# Uncomment to use:
#
# SSH_HOST="root@192.168.1.20"
# PROCESS_NAME="my-service"
#
# if ssh "$SSH_HOST" "pgrep -f $PROCESS_NAME" &>/dev/null; then
#     echo "✅ Process $PROCESS_NAME is running"
#     exit 0
# else
#     echo "❌ Process $PROCESS_NAME is not running"
#     exit 1
# fi

# ============================================================================
# CUSTOM HEALTH CHECK
# ============================================================================
#
# Or write your own health check logic here

echo "⚠️  This is a template health check script"
echo "Please customize this file for your service"
echo ""
echo "Examples above show common health check patterns"
echo ""
echo "For now, this is a no-op health check (always passes)"

exit 0
