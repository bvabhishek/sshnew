#!/bin/bash

# Deploy SSH Vulnerable Lab on Remote Machine
# Run this script directly on the remote machine: root@9.30.123.170

set -e

echo "========================================="
echo "SSH Vulnerable Lab - Remote Deployment"
echo "========================================="
echo ""

# Navigate to project directory
cd /root/abhishek/sshnew

# Stop and remove existing container
echo "[1/4] Cleaning up existing containers and port conflicts..."
docker stop vulnerable-ssh-server 2>/dev/null || true
docker rm vulnerable-ssh-server 2>/dev/null || true
docker rmi vulnerable-ssh-server 2>/dev/null || true

# Find and stop any container using port 2222
PORT_CONTAINER=$(docker ps -q --filter "publish=2222")
if [ ! -z "$PORT_CONTAINER" ]; then
    echo "Found container using port 2222: $PORT_CONTAINER"
    docker stop $PORT_CONTAINER
    docker rm $PORT_CONTAINER
fi

# Check if port is still in use by non-Docker process
if lsof -Pi :2222 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠ Port 2222 is in use by another process"
    echo "Finding process using port 2222..."
    lsof -i :2222
    echo ""
    echo "To free the port, run: kill -9 \$(lsof -t -i:2222)"
    echo "Or use a different port by editing the docker run command"
fi

echo "✓ Cleanup complete"
echo ""

# Build Docker image
echo "[2/4] Building Docker image..."
docker build -t vulnerable-ssh-server . || {
    echo "✗ Failed to build Docker image"
    exit 1
}
echo "✓ Docker image built successfully"
echo ""

# Start container
echo "[3/4] Starting vulnerable SSH server..."
docker run -d \
    --name vulnerable-ssh-server \
    -p 2222:22 \
    vulnerable-ssh-server || {
    echo "✗ Failed to start container"
    exit 1
}
echo "✓ Container started successfully"
echo ""

# Wait for SSH to be ready
echo "[4/4] Waiting for SSH service..."
sleep 5

# Verify container is running
if docker ps | grep -q vulnerable-ssh-server; then
    echo "✓ Container is running"
else
    echo "✗ Container failed to start"
    docker logs vulnerable-ssh-server
    exit 1
fi
echo ""

# Test SSH connectivity
echo "Testing SSH connectivity..."
timeout 5 nc -zv localhost 2222 2>&1 | grep -q "succeeded" && {
    echo "✓ SSH port is accessible"
} || {
    echo "⚠ SSH port test inconclusive (may still be starting)"
}
echo ""

# Display success message
echo "========================================="
echo "✓ Deployment Successful!"
echo "========================================="
echo ""
echo "SSH Server Details:"
echo "  Host: 9.30.123.170 (or localhost from this machine)"
echo "  Port: 2222"
echo ""
echo "Test Credentials:"
echo "  root:toor"
echo "  testuser:password123"
echo "  admin:admin"
echo "  user1:user1"
echo "  validuser:ValidPass123!"
echo ""
echo "Test Commands:"
echo "  # From this machine:"
echo "  ssh -p 2222 testuser@localhost"
echo ""
echo "  # From another machine:"
echo "  ssh -p 2222 testuser@9.30.123.170"
echo ""
echo "  # Run vulnerability tests:"
echo "  ./test_vulnerabilities.sh"
echo ""
echo "  # View container logs:"
echo "  docker logs -f vulnerable-ssh-server"
echo ""
echo "  # Stop server:"
echo "  docker stop vulnerable-ssh-server"
echo ""
echo "⚠ WARNING: This is a vulnerable server for testing only!"
echo ""

# Made with Bob
