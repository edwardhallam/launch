# Troubleshooting Guide

Common issues and solutions for Launch CI/CD platform.

## Table of Contents

- [GitHub Actions Issues](#github-actions-issues)
- [SSH Connection Problems](#ssh-connection-problems)
- [Docker Deployment Failures](#docker-deployment-failures)
- [Proxmox API Errors](#proxmox-api-errors)
- [Health Check Failures](#health-check-failures)
- [Performance Issues](#performance-issues)
- [Security & Secrets](#security--secrets)

## GitHub Actions Issues

### Runner Offline

**Symptoms:**
- Workflows stuck in "Queued" state
- Runner shows as "Offline" in Settings > Actions > Runners

**Diagnosis:**
```bash
# Check runner service status
pct exec 200 -- systemctl status actions.runner

# Check runner logs
pct exec 200 -- journalctl -u actions.runner -f -n 100
```

**Solutions:**
1. **Restart runner service:**
   ```bash
   pct exec 200 -- systemctl restart actions.runner
   ```

2. **Check network connectivity:**
   ```bash
   pct exec 200 -- ping -c 3 github.com
   pct exec 200 -- curl -I https://api.github.com
   ```

3. **Reconfigure runner:**
   ```bash
   pct enter 200
   cd /opt/actions-runner
   sudo ./svc.sh stop
   ./config.sh remove --token YOUR_OLD_TOKEN
   ./config.sh --url https://github.com/USER/REPO --token NEW_TOKEN
   sudo ./svc.sh install
   sudo ./svc.sh start
   ```

### Workflow Not Triggering

**Symptoms:**
- Push to main doesn't trigger workflow
- Changes to services/ folder ignored

**Diagnosis:**
```bash
# Check workflow file syntax
cat .github/workflows/deploy.yml

# Verify path filters
git log --oneline -1 --name-only
```

**Solutions:**
1. **Verify path matches filter:**
   - Workflow filters for `services/**`
   - Ensure changes are in `services/` directory
   - Not `Services/` or `service/` (case-sensitive)

2. **Check workflow is enabled:**
   - Go to Actions tab
   - Click workflow name
   - Ensure it's not disabled

3. **Verify branch name:**
   - Workflow triggers on `main` branch
   - Check: `git branch` shows `main`
   - Not `master` or other branch

### Workflow Fails Immediately

**Symptoms:**
- Workflow starts but fails in first few steps
- Error: "No runner available"

**Solutions:**
1. **Verify runner labels match:**
   ```yaml
   # In workflow file
   runs-on: self-hosted  # Must match runner labels
   ```

2. **Check runner capacity:**
   - Can only run limited concurrent jobs
   - Wait for other jobs to complete
   - Or add more runners

## SSH Connection Problems

### Connection Refused

**Symptoms:**
- `ssh: connect to host X.X.X.X port 22: Connection refused`
- Deploy fails with SSH error

**Diagnosis:**
```bash
# From runner, test connection
pct exec 200 -- ssh -v root@TARGET_IP

# Check if SSH is running on target
pct exec 201 -- systemctl status ssh
```

**Solutions:**
1. **Start SSH service on target:**
   ```bash
   pct exec 201 -- systemctl start ssh
   pct exec 201 -- systemctl enable ssh
   ```

2. **Check firewall:**
   ```bash
   # On target
   pct exec 201 -- ufw status
   pct exec 201 -- ufw allow 22/tcp
   ```

3. **Verify IP address:**
   ```bash
   # Get actual IP
   pct exec 201 -- ip addr show eth0
   
   # Update DOCKER_HOST_IP secret if needed
   ```

### Permission Denied (publickey)

**Symptoms:**
- `Permission denied (publickey)`
- SSH key not accepted

**Diagnosis:**
```bash
# Check key is loaded
pct exec 200 -- ls -la /root/.ssh/
pct exec 200 -- cat /root/.ssh/id_ed25519
```

**Solutions:**
1. **Verify SSH key in GitHub Secrets:**
   - Settings > Secrets > SSH_PRIVATE_KEY
   - Must be complete private key including headers
   - `-----BEGIN OPENSSH PRIVATE KEY-----` ... `-----END OPENSSH PRIVATE KEY-----`

2. **Check public key on target:**
   ```bash
   pct exec 201 -- cat /root/.ssh/authorized_keys
   # Should contain matching public key
   ```

3. **Fix permissions:**
   ```bash
   # On runner
   pct exec 200 -- chmod 600 /root/.ssh/id_ed25519
   pct exec 200 -- chmod 700 /root/.ssh
   
   # On target
   pct exec 201 -- chmod 600 /root/.ssh/authorized_keys
   pct exec 201 -- chmod 700 /root/.ssh
   ```

4. **Generate new key pair:**
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/launch-new
   # Update GitHub secret with new private key
   # Update target authorized_keys with new public key
   ```

### Host Key Verification Failed

**Symptoms:**
- `Host key verification failed`

**Solutions:**
```bash
# Add host to known_hosts
pct exec 200 -- ssh-keyscan TARGET_IP >> /root/.ssh/known_hosts

# Or disable strict checking (less secure)
# Add to workflow:
env:
  SSH_OPTS: "-o StrictHostKeyChecking=no"
```

## Docker Deployment Failures

### Cannot Connect to Docker Daemon

**Symptoms:**
- `Cannot connect to the Docker daemon`
- Docker commands fail on target

**Diagnosis:**
```bash
# Check Docker service
ssh root@DOCKER_HOST_IP systemctl status docker

# Test Docker
ssh root@DOCKER_HOST_IP docker ps
```

**Solutions:**
```bash
# Start Docker
ssh root@DOCKER_HOST_IP systemctl start docker
ssh root@DOCKER_HOST_IP systemctl enable docker

# Check if user has Docker permissions
ssh root@DOCKER_HOST_IP docker run hello-world
```

### Container Won't Start

**Symptoms:**
- `docker-compose up` completes but container exits
- Container in "Exited" state

**Diagnosis:**
```bash
# Check container status
ssh root@DOCKER_HOST_IP docker ps -a | grep SERVICE

# View logs
ssh root@DOCKER_HOST_IP "cd /opt/services/SERVICE && docker-compose logs"

# Inspect container
ssh root@DOCKER_HOST_IP docker inspect CONTAINER_NAME
```

**Solutions:**
1. **Check logs for errors:**
   ```bash
   docker-compose logs --tail=100
   ```

2. **Verify configuration:**
   - Check docker-compose.yml syntax
   - Verify environment variables
   - Check volume mounts exist

3. **Test image locally:**
   ```bash
   docker pull IMAGE_NAME
   docker run -it IMAGE_NAME /bin/sh
   ```

4. **Resource constraints:**
   ```bash
   # Check host resources
   free -h
   df -h
   ```

### Port Already in Use

**Symptoms:**
- `bind: address already in use`
- Container fails to start

**Solutions:**
```bash
# Find process using port
ssh root@DOCKER_HOST_IP "lsof -i :PORT_NUMBER"

# Or check all containers
ssh root@DOCKER_HOST_IP "docker ps --format '{{.Names}}\t{{.Ports}}'"

# Change port in docker-compose.yml
ports:
  - "8081:80"  # Changed from 8080:80
```

## Proxmox API Errors

### 401 Unauthorized

**Symptoms:**
- Proxmox API calls fail with 401
- "authentication failed"

**Solutions:**
1. **Verify API token format:**
   ```bash
   # Should be: USER@REALM!TOKENID=SECRET
   # Example: automation@pve!deploy=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ```

2. **Test API token:**
   ```bash
   curl -k \
     -H "Authorization: PVEAPIToken=automation@pve!deploy=SECRET" \
     https://PROXMOX_IP:8006/api2/json/nodes
   ```

3. **Check token hasn't expired:**
   ```bash
   pveum user token list automation@pve
   ```

4. **Regenerate token:**
   ```bash
   pveum user token remove automation@pve deploy
   pveum user token add automation@pve deploy -privsep 0
   # Update GitHub secret with new token
   ```

### 403 Permission Denied

**Symptoms:**
- API call fails with 403
- "insufficient permissions"

**Solutions:**
```bash
# Check user permissions
pveum user list

# Grant necessary permissions
pveum acl modify / -user automation@pve -role Administrator

# Or create custom role with specific permissions
pveum role add Deploy -privs "VM.Allocate VM.Config.Disk VM.Config.Network VM.PowerMgmt"
pveum acl modify / -user automation@pve -role Deploy
```

### Cannot Create LXC

**Symptoms:**
- LXC creation fails
- "template not found"

**Solutions:**
1. **Download template:**
   ```bash
   pveam update
   pveam available | grep ubuntu
   pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
   ```

2. **Check storage:**
   ```bash
   pvesm status
   df -h
   ```

3. **Verify template path:**
   ```bash
   ls -la /var/lib/vz/template/cache/
   ```

## Health Check Failures

### HTTP Health Check Fails

**Symptoms:**
- Health check returns non-200 status
- Service not responding

**Diagnosis:**
```bash
# Test endpoint manually
curl -v http://SERVICE_IP:PORT/health

# Check from runner
pct exec 200 -- curl -v http://SERVICE_IP:PORT/health
```

**Solutions:**
1. **Verify service is running:**
   ```bash
   ssh root@SERVICE_HOST "docker ps | grep SERVICE"
   ```

2. **Check port binding:**
   ```bash
   ssh root@SERVICE_HOST "netstat -tulpn | grep PORT"
   ```

3. **Test network connectivity:**
   ```bash
   pct exec 200 -- ping -c 3 SERVICE_IP
   pct exec 200 -- telnet SERVICE_IP PORT
   ```

4. **Check service logs:**
   ```bash
   ssh root@SERVICE_HOST "docker logs CONTAINER"
   ```

### Container Health Check Fails

**Symptoms:**
- Container shows as "unhealthy"
- Docker health check failing

**Solutions:**
```bash
# Check container health status
docker inspect CONTAINER | jq '.[].State.Health'

# View health check logs
docker inspect CONTAINER | jq '.[].State.Health.Log'

# Adjust health check in docker-compose.yml
healthcheck:
  interval: 60s    # Increase interval
  timeout: 30s     # Increase timeout
  retries: 5       # Increase retries
  start_period: 60s  # Increase start period
```

## Performance Issues

### Slow Deployments

**Symptoms:**
- Deployments take > 10 minutes
- Timeouts during deployment

**Solutions:**
1. **Check network speed:**
   ```bash
   # Test speed to Docker host
   pct exec 200 -- iperf3 -c DOCKER_HOST_IP
   ```

2. **Optimize Docker images:**
   - Use smaller base images (alpine)
   - Multi-stage builds
   - Layer caching

3. **Parallel deployments:**
   - Check `max-parallel: 2` in workflow
   - Reduce if resource constrained

4. **Increase timeouts:**
   ```bash
   # In deploy script
   timeout 1200 ./deploy.sh  # 20 minutes
   ```

### High Resource Usage

**Symptoms:**
- Runner LXC using excessive CPU/RAM
- Deployments slow or fail

**Solutions:**
```bash
# Check resource usage
pct exec 200 -- top
pct exec 200 -- free -h
pct exec 200 -- df -h

# Increase LXC resources
pct set 200 -memory 8192  # 8GB RAM
pct set 200 -cores 4      # 4 CPU cores

# Restart LXC
pct reboot 200
```

## Security & Secrets

### Secret Not Available in Workflow

**Symptoms:**
- Environment variable is empty
- Deployment fails with missing credentials

**Solutions:**
1. **Verify secret is set:**
   - Settings > Secrets and variables > Actions
   - Check secret name matches exactly (case-sensitive)

2. **Check secret is passed to job:**
   ```yaml
   env:
     PROXMOX_API_TOKEN: ${{ secrets.PROXMOX_API_TOKEN }}
   ```

3. **Secrets not passed to forked repos:**
   - If testing in fork, re-add secrets

### Accidentally Committed Secrets

**Symptoms:**
- Secrets visible in git history
- Security concern

**Solutions:**
1. **Remove from git history:**
   ```bash
   # Use BFG or git-filter-branch
   bfg --delete-files secret.env
   git push --force
   ```

2. **Rotate compromised secrets:**
   - Generate new SSH keys
   - Create new API tokens
   - Update GitHub Secrets

3. **Prevent future commits:**
   ```bash
   # Add to .gitignore
   echo ".env" >> .gitignore
   echo "*.key" >> .gitignore
   echo "*.pem" >> .gitignore
   ```

## Getting More Help

If issues persist:

1. **Check workflow logs:**
   - Actions tab > Failed workflow > View logs
   - Download log archive for analysis

2. **Enable debug logging:**
   ```yaml
   # Add to workflow
   env:
     ACTIONS_STEP_DEBUG: true
     ACTIONS_RUNNER_DEBUG: true
   ```

3. **Test components individually:**
   - SSH connection: `ssh root@host`
   - Docker: `docker run hello-world`
   - API: `curl -k https://proxmox:8006/api2/json`

4. **Review documentation:**
   - [SETUP.md](./SETUP.md) - Setup guide
   - [PRD.md](../PRD.md) - Architecture details
   - Service README.md files

5. **Check system logs:**
   ```bash
   # Runner logs
   pct exec 200 -- journalctl -u actions.runner -f

   # Docker host logs
   ssh root@DOCKER_HOST journalctl -f

   # Proxmox logs
   tail -f /var/log/pve/tasks/active
   ```

---

**Document Version:** 1.0  
**Last Updated:** November 16, 2025
