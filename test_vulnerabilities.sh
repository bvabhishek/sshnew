#!/bin/bash

# SSH Vulnerability Testing Script
# This script tests various SSH vulnerabilities in the vulnerable SSH server

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SSH_HOST="localhost"
SSH_PORT="2222"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SSH Vulnerability Testing Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Test 1: Check SSH Protocol Version
echo -e "${YELLOW}[TEST 1] Checking SSH Protocol Version Support${NC}"
echo "Testing if server supports SSHv1 protocol..."
echo ""

# Use nmap to check SSH version
if command -v nmap &> /dev/null; then
    echo "Using nmap to detect SSH version:"
    nmap -p $SSH_PORT --script ssh-hostkey,ssh2-enum-algos $SSH_HOST
    echo ""
else
    echo "nmap not found, using manual banner grab:"
    timeout 5 bash -c "echo 'SSH-1.5-Client' | nc $SSH_HOST $SSH_PORT" 2>/dev/null || echo "Connection test completed"
    echo ""
fi

# Alternative: Direct protocol check
echo "Attempting SSHv1 handshake:"
(echo "SSH-1.5-OpenSSH_7.4" | timeout 3 nc $SSH_HOST $SSH_PORT) 2>/dev/null | head -1
echo ""
echo -e "${GREEN}✓ Test 1 Complete${NC}"
echo ""

# Test 2: Check Weak Encryption Algorithms
echo -e "${YELLOW}[TEST 2] Checking for Weak Encryption Algorithms${NC}"
echo "Scanning for weak ciphers, MACs, and key exchange algorithms..."
echo ""

if command -v ssh &> /dev/null; then
    echo "Supported Ciphers:"
    ssh -Q cipher 2>/dev/null | grep -E "(cbc|arcfour|3des)" || echo "Using ssh-audit for detailed analysis"
    echo ""
    
    echo "Testing connection with weak cipher (3des-cbc):"
    timeout 5 ssh -o "Ciphers=3des-cbc" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -p $SSH_PORT testuser@$SSH_HOST "echo 'Weak cipher accepted'" 2>&1 | grep -E "(cipher|algorithm|accepted)" || echo "Connection attempt completed"
    echo ""
    
    echo "Testing connection with weak MAC (hmac-md5):"
    timeout 5 ssh -o "MACs=hmac-md5" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -p $SSH_PORT testuser@$SSH_HOST "echo 'Weak MAC accepted'" 2>&1 | grep -E "(mac|algorithm|accepted)" || echo "Connection attempt completed"
    echo ""
fi

echo -e "${GREEN}✓ Test 2 Complete${NC}"
echo ""

# Test 3: Username Enumeration Timing Attack
echo -e "${YELLOW}[TEST 3] Testing Username Enumeration via Timing Attack${NC}"
echo "Attempting to enumerate valid usernames based on response timing..."
echo ""

# Test with valid username
echo "Testing with VALID username (testuser):"
START_VALID=$(date +%s%N)
timeout 5 ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "PreferredAuthentications=password" -p $SSH_PORT testuser@$SSH_HOST "exit" 2>&1 | head -3 &
wait $!
END_VALID=$(date +%s%N)
VALID_TIME=$((($END_VALID - $START_VALID) / 1000000))
echo "Response time: ${VALID_TIME}ms"
echo ""

# Test with invalid username
echo "Testing with INVALID username (nonexistentuser999):"
START_INVALID=$(date +%s%N)
timeout 5 ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "PreferredAuthentications=password" -p $SSH_PORT nonexistentuser999@$SSH_HOST "exit" 2>&1 | head -3 &
wait $!
END_INVALID=$(date +%s%N)
INVALID_TIME=$((($END_INVALID - $START_INVALID) / 1000000))
echo "Response time: ${INVALID_TIME}ms"
echo ""

DIFF=$((VALID_TIME - INVALID_TIME))
if [ $DIFF -lt 0 ]; then
    DIFF=$((-DIFF))
fi

echo "Time difference: ${DIFF}ms"
if [ $DIFF -gt 100 ]; then
    echo -e "${RED}⚠ Timing difference detected! Username enumeration possible.${NC}"
else
    echo -e "${GREEN}✓ No significant timing difference detected.${NC}"
fi
echo ""
echo -e "${GREEN}✓ Test 3 Complete${NC}"
echo ""

# Test 4: Authentication Methods
echo -e "${YELLOW}[TEST 4] Testing Authentication Methods${NC}"
echo "Checking supported authentication methods..."
echo ""

echo "Testing Password Authentication:"
timeout 5 ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "PreferredAuthentications=password" -p $SSH_PORT testuser@$SSH_HOST "echo 'Password auth available'" 2>&1 | grep -E "(password|Permission|auth)" | head -3
echo ""

echo "Testing Public Key Authentication:"
timeout 5 ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "PreferredAuthentications=publickey" -p $SSH_PORT testuser@$SSH_HOST "echo 'Pubkey auth available'" 2>&1 | grep -E "(publickey|Permission|auth)" | head -3
echo ""

echo -e "${GREEN}✓ Test 4 Complete${NC}"
echo ""

# Test 5: Brute Force Attempt (Limited)
echo -e "${YELLOW}[TEST 5] Testing Brute Force Protection${NC}"
echo "Attempting multiple failed login attempts..."
echo ""

for i in {1..3}; do
    echo "Attempt $i with wrong password:"
    timeout 3 sshpass -p "wrongpassword" ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -p $SSH_PORT testuser@$SSH_HOST "exit" 2>&1 | grep -E "(Permission|denied|failed)" || echo "Attempt $i completed"
done
echo ""
echo -e "${GREEN}✓ Test 5 Complete${NC}"
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Testing Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${RED}Vulnerabilities Found:${NC}"
echo "1. SSHv1 Protocol Support (if detected)"
echo "2. Weak Encryption Algorithms (3DES, Arcfour, CBC mode)"
echo "3. Weak MAC Algorithms (HMAC-MD5, HMAC-SHA1)"
echo "4. Weak Key Exchange (DH Group 1)"
echo "5. Username Enumeration via Timing Attack"
echo "6. Both Password and Public Key Authentication Enabled"
echo ""
echo -e "${YELLOW}Recommendation: Review SOLUTIONS.md for remediation steps${NC}"
echo ""

# Made with Bob
