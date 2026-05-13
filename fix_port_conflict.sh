#!/bin/bash

# Quick Fix for Port 2222 Conflict
# Run this script to free up port 2222

echo "========================================="
echo "Port 2222 Conflict Resolution"
echo "========================================="
echo ""

# Stop all containers using port 2222
echo "[1/3] Stopping containers using port 2222..."
PORT_CONTAINERS=$(docker ps -q --filter "publish=2222")
if [ ! -z "$PORT_CONTAINERS" ]; then
    echo "Found containers using port 2222:"
    docker ps --filter "publish=2222"
    echo ""
    echo "Stopping containers..."
    docker stop $PORT_CONTAINERS
    docker rm $PORT_CONTAINERS
    echo "✓ Containers stopped and removed"
else
    echo "No Docker containers using port 2222"
fi
echo ""

# Check for non-Docker processes
echo "[2/3] Checking for non-Docker processes on port 2222..."
if lsof -Pi :2222 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠ Port 2222 is in use by another process:"
    lsof -i :2222
    echo ""
    echo "To kill the process, run:"
    echo "  sudo kill -9 \$(lsof -t -i:2222)"
    echo ""
    read -p "Kill the process now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo kill -9 $(lsof -t -i:2222) 2>/dev/null
        echo "✓ Process killed"
    fi
else
    echo "✓ No other processes using port 2222"
fi
echo ""

# Verify port is free
echo "[3/3] Verifying port 2222 is free..."
if ! lsof -Pi :2222 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "✓ Port 2222 is now free"
    echo ""
    echo "You can now run:"
    echo "  ./deploy_on_remote.sh"
else
    echo "✗ Port 2222 is still in use"
    echo "Please manually stop the process using port 2222"
fi
echo ""

# Made with Bob
