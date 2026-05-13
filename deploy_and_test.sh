#!/bin/bash

# SSH Vulnerable Lab - Deployment and Testing Script
# This script builds, deploys, and tests the vulnerable SSH server

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SSH Vulnerable Lab - Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Build Docker Image
echo -e "${YELLOW}[1/5] Building Docker image...${NC}"
docker build -t vulnerable-ssh-server . || {
    echo -e "${RED}Failed to build Docker image${NC}"
    exit 1
}
echo -e "${GREEN}✓ Docker image built successfully${NC}"
echo ""

# Step 2: Stop any existing container
echo -e "${YELLOW}[2/5] Cleaning up existing containers...${NC}"
docker stop vulnerable-ssh-server 2>/dev/null || true
docker rm vulnerable-ssh-server 2>/dev/null || true
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# Step 3: Start the container
echo -e "${YELLOW}[3/5] Starting vulnerable SSH server...${NC}"
docker run -d \
    --name vulnerable-ssh-server \
    -p 2222:22 \
    vulnerable-ssh-server || {
    echo -e "${RED}Failed to start container${NC}"
    exit 1
}
echo -e "${GREEN}✓ Container started successfully${NC}"
echo ""

# Step 4: Wait for SSH to be ready
echo -e "${YELLOW}[4/5] Waiting for SSH service to start...${NC}"
sleep 5

# Check if container is running
if docker ps | grep -q vulnerable-ssh-server; then
    echo -e "${GREEN}✓ Container is running${NC}"
else
    echo -e "${RED}✗ Container failed to start${NC}"
    docker logs vulnerable-ssh-server
    exit 1
fi
echo ""

# Step 5: Basic connectivity test
echo -e "${YELLOW}[5/5] Testing SSH connectivity...${NC}"
timeout 5 nc -zv localhost 2222 2>&1 | grep -q "succeeded" && {
    echo -e "${GREEN}✓ SSH port is accessible${NC}"
} || {
    echo -e "${RED}✗ Cannot connect to SSH port${NC}"
    exit 1
}
echo ""

# Display container information
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Deployment Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}SSH Server Details:${NC}"
echo "  Host: localhost"
echo "  Port: 2222"
echo ""
echo -e "${GREEN}Test Credentials:${NC}"
echo "  root:toor"
echo "  testuser:password123"
echo "  admin:admin"
echo "  user1:user1"
echo ""
echo -e "${YELLOW}Quick Test Commands:${NC}"
echo "  ssh -p 2222 testuser@localhost"
echo "  ./test_vulnerabilities.sh"
echo "  python3 advanced_tests.py"
echo ""
echo -e "${YELLOW}View Logs:${NC}"
echo "  docker logs -f vulnerable-ssh-server"
echo ""
echo -e "${YELLOW}Stop Server:${NC}"
echo "  docker stop vulnerable-ssh-server"
echo "  docker rm vulnerable-ssh-server"
echo ""
echo -e "${RED}⚠ WARNING: This is a vulnerable server for testing only!${NC}"
echo ""

# Made with Bob
