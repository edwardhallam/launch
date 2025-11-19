#!/bin/bash
#
# Setup Deploy User Script
#
# This script provisions a 'deploy' user on a target system (VM/LXC).
# It should be run ONCE as root on the target system.
#
# Usage: ./setup-user.sh [USERNAME] [PUBLIC_KEY]
#
# Arguments:
#   USERNAME    - Name of the user to create (default: deploy)
#   PUBLIC_KEY  - SSH public key to authorize (optional, can be passed via stdin)

set -e

USERNAME="${1:-deploy}"
PUBLIC_KEY="${2:-}"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}🚀 Setting up user '${USERNAME}'...${NC}"

# 1. Create user if not exists
if id "$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' already exists."
else
    echo "Creating user '$USERNAME'..."
    useradd -m -s /bin/bash "$USERNAME"
fi

# 2. Setup SSH access
echo "Configuring SSH access..."
USER_HOME="/home/$USERNAME"
mkdir -p "$USER_HOME/.ssh"
chmod 700 "$USER_HOME/.ssh"

# If public key not provided as arg, try reading from stdin or ask
if [ -z "$PUBLIC_KEY" ]; then
    if [ ! -t 0 ]; then
        PUBLIC_KEY=$(cat)
    else
        echo "Please paste the SSH public key (starts with ssh-ed25519 or ssh-rsa):"
        read -r PUBLIC_KEY
    fi
fi

if [ -n "$PUBLIC_KEY" ]; then
    echo "$PUBLIC_KEY" > "$USER_HOME/.ssh/authorized_keys"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"
    chown -R "$USERNAME:$USERNAME" "$USER_HOME/.ssh"
    echo "✅ SSH key added."
else
    echo "⚠️  No public key provided. SSH access might not work."
fi

# 3. Add to Docker group (if Docker exists)
if getent group docker >/dev/null; then
    echo "Adding '$USERNAME' to docker group..."
    usermod -aG docker "$USERNAME"
fi

# 4. Setup Sudoers for Service Management
# We want to allow this user to restart services without password
echo "Configuring sudoers..."
SUDO_FILE="/etc/sudoers.d/$USERNAME"

cat > "$SUDO_FILE" <<EOF
# Allow $USERNAME to manage services
$USERNAME ALL=(root) NOPASSWD: /usr/bin/systemctl restart *, /usr/bin/systemctl status *, /usr/bin/systemctl start *, /usr/bin/systemctl stop *
EOF

chmod 440 "$SUDO_FILE"

echo -e "${GREEN}✅ Setup complete for user '${USERNAME}'!${NC}"
