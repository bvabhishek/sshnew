#!/bin/bash

# Remote Deployment Script for SSH Vulnerable Lab
# Deploys to remote machine: 9.30.123.170

set -e

REMOTE_HOST="9.30.123.170"
REMOTE_USER="root"
REMOTE_PASS="Mint@9876543210"
REMOTE_DIR="/root/abhishek/sshnew"

echo "========================================="
echo "Remote Deployment to $REMOTE_HOST"
echo "========================================="
echo ""

# Create deployment package
echo "[1/4] Creating deployment package..."
tar -czf ssh-vulnerable-lab.tar.gz \
    Dockerfile \
    docker-compose.yml \
    test_vulnerabilities.sh \
    advanced_tests.py \
    deploy_and_test.sh \
    README.md \
    VULNERABILITIES.md \
    SOLUTIONS.md \
    PROJECT_SUMMARY.md

echo "✓ Package created"
echo ""

# Copy files to remote machine
echo "[2/4] Copying files to remote machine..."
sshpass -p "$REMOTE_PASS" scp -o StrictHostKeyChecking=no \
    ssh-vulnerable-lab.tar.gz \
    ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/

echo "✓ Files copied"
echo ""

# Extract and build on remote machine
echo "[3/4] Extracting and building on remote machine..."
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no \
    ${REMOTE_USER}@${REMOTE_HOST} << 'ENDSSH'
cd /root/abhishek/sshnew
tar -xzf ssh-vulnerable-lab.tar.gz
chmod +x deploy_and_test.sh test_vulnerabilities.sh advanced_tests.py
echo "Files extracted and permissions set"
ENDSSH

echo "✓ Files extracted"
echo ""

# Build and deploy
echo "[4/4] Building Docker image on remote machine..."
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no \
    ${REMOTE_USER}@${REMOTE_HOST} << 'ENDSSH'
cd /root/abhishek/sshnew

# Stop and remove existing container
docker stop vulnerable-ssh-server 2>/dev/null || true
docker rm vulnerable-ssh-server 2>/dev/null || true

# Build new image
docker build -t vulnerable-ssh-server .

# Run container
docker run -d \
    --name vulnerable-ssh-server \
    -p 2222:22 \
    vulnerable-ssh-server

# Wait for SSH to start
sleep 5

# Check status
if docker ps | grep -q vulnerable-ssh-server; then
    echo ""
    echo "========================================="
    echo "✓ Deployment Successful!"
    echo "========================================="
    echo ""
    echo "SSH Server Details:"
    echo "  Host: 9.30.123.170"
    echo "  Port: 2222"
    echo ""
    echo "Test Credentials:"
    echo "  root:toor"
    echo "  testuser:password123"
    echo "  admin:admin"
    echo ""
    echo "Test from your machine:"
    echo "  ssh -p 2222 testuser@9.30.123.170"
    echo ""
else
    echo "✗ Container failed to start"
    docker logs vulnerable-ssh-server
    exit 1
fi
ENDSSH

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""
echo "Connect to the vulnerable SSH server:"
echo "  ssh -p 2222 testuser@9.30.123.170"
echo "  Password: password123"
echo ""
echo "Run tests on remote machine:"
echo "  ssh root@9.30.123.170"
echo "  cd /root/abhishek/sshnew"
echo "  ./test_vulnerabilities.sh"
echo ""

# Cleanup local package
rm -f ssh-vulnerable-lab.tar.gz

# Made with Bob
