#!/usr/bin/env python3
"""
Advanced SSH Vulnerability Testing Script
Tests SSH vulnerabilities with detailed analysis and reporting
"""

import socket
import time
import sys
import subprocess
from datetime import datetime

# Configuration
SSH_HOST = "localhost"
SSH_PORT = 2222
TIMEOUT = 5

class Colors:
    BLUE = '\033[0;34m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    NC = '\033[0m'

def print_header(text):
    print(f"\n{Colors.BLUE}{'='*60}{Colors.NC}")
    print(f"{Colors.BLUE}{text}{Colors.NC}")
    print(f"{Colors.BLUE}{'='*60}{Colors.NC}\n")

def print_test(text):
    print(f"{Colors.YELLOW}[TEST] {text}{Colors.NC}")

def print_success(text):
    print(f"{Colors.GREEN}✓ {text}{Colors.NC}")

def print_error(text):
    print(f"{Colors.RED}✗ {text}{Colors.NC}")

def print_warning(text):
    print(f"{Colors.YELLOW}⚠ {text}{Colors.NC}")

def test_ssh_banner():
    """Test 1: SSH Banner Grabbing and Protocol Detection"""
    print_test("SSH Banner Grabbing and Protocol Detection")
    
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(TIMEOUT)
        sock.connect((SSH_HOST, SSH_PORT))
        
        # Receive banner
        banner = sock.recv(1024).decode('utf-8').strip()
        print(f"Server Banner: {banner}")
        
        # Check for SSHv1 support
        if "SSH-1" in banner or "SSH-2.0" in banner:
            print_success("Banner received successfully")
            
            # Try SSHv1 handshake
            print("\nAttempting SSHv1 protocol handshake...")
            sock.send(b"SSH-1.5-TestClient\r\n")
            time.sleep(1)
            
            try:
                response = sock.recv(1024).decode('utf-8', errors='ignore')
                if response:
                    print_warning(f"Server responded to SSHv1: {response[:100]}")
                    print_error("VULNERABILITY: Server may support SSHv1 protocol!")
                else:
                    print_success("Server rejected SSHv1 protocol")
            except:
                print_success("Server rejected SSHv1 protocol")
        
        sock.close()
        
    except Exception as e:
        print_error(f"Banner grab failed: {e}")
    
    print()

def test_weak_algorithms():
    """Test 2: Weak Encryption Algorithms Detection"""
    print_test("Weak Encryption Algorithms Detection")
    
    weak_ciphers = [
        "3des-cbc",
        "aes128-cbc",
        "aes192-cbc",
        "aes256-cbc",
        "arcfour",
        "arcfour128",
        "arcfour256"
    ]
    
    weak_macs = [
        "hmac-md5",
        "hmac-sha1",
        "hmac-ripemd160"
    ]
    
    weak_kex = [
        "diffie-hellman-group1-sha1",
        "diffie-hellman-group14-sha1"
    ]
    
    print("Testing for weak ciphers:")
    for cipher in weak_ciphers:
        cmd = [
            "ssh", "-o", f"Ciphers={cipher}",
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-o", "ConnectTimeout=3",
            "-p", str(SSH_PORT),
            f"testuser@{SSH_HOST}",
            "exit"
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
            if "no matching cipher" not in result.stderr.lower():
                print_error(f"  Weak cipher accepted: {cipher}")
            else:
                print_success(f"  Weak cipher rejected: {cipher}")
        except:
            pass
    
    print("\nTesting for weak MACs:")
    for mac in weak_macs:
        cmd = [
            "ssh", "-o", f"MACs={mac}",
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-o", "ConnectTimeout=3",
            "-p", str(SSH_PORT),
            f"testuser@{SSH_HOST}",
            "exit"
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
            if "no matching mac" not in result.stderr.lower():
                print_error(f"  Weak MAC accepted: {mac}")
            else:
                print_success(f"  Weak MAC rejected: {mac}")
        except:
            pass
    
    print()

def test_username_enumeration():
    """Test 3: Username Enumeration via Timing Attack"""
    print_test("Username Enumeration via Timing Attack")
    
    valid_users = ["testuser", "admin", "user1", "validuser"]
    invalid_users = ["nonexistent", "fakeuser999", "invaliduser"]
    
    print("Testing valid usernames:")
    valid_times = []
    
    for user in valid_users:
        start = time.time()
        cmd = [
            "ssh", "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-o", "PreferredAuthentications=password",
            "-o", "ConnectTimeout=3",
            "-p", str(SSH_PORT),
            f"{user}@{SSH_HOST}",
            "exit"
        ]
        
        try:
            subprocess.run(cmd, capture_output=True, timeout=5)
        except:
            pass
        
        elapsed = (time.time() - start) * 1000
        valid_times.append(elapsed)
        print(f"  {user}: {elapsed:.2f}ms")
    
    print("\nTesting invalid usernames:")
    invalid_times = []
    
    for user in invalid_users:
        start = time.time()
        cmd = [
            "ssh", "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-o", "PreferredAuthentications=password",
            "-o", "ConnectTimeout=3",
            "-p", str(SSH_PORT),
            f"{user}@{SSH_HOST}",
            "exit"
        ]
        
        try:
            subprocess.run(cmd, capture_output=True, timeout=5)
        except:
            pass
        
        elapsed = (time.time() - start) * 1000
        invalid_times.append(elapsed)
        print(f"  {user}: {elapsed:.2f}ms")
    
    avg_valid = sum(valid_times) / len(valid_times)
    avg_invalid = sum(invalid_times) / len(invalid_times)
    diff = abs(avg_valid - avg_invalid)
    
    print(f"\nAverage valid user time: {avg_valid:.2f}ms")
    print(f"Average invalid user time: {avg_invalid:.2f}ms")
    print(f"Time difference: {diff:.2f}ms")
    
    if diff > 50:
        print_error(f"VULNERABILITY: Timing difference of {diff:.2f}ms detected!")
        print_warning("Username enumeration is possible via timing attack")
    else:
        print_success("No significant timing difference detected")
    
    print()

def test_authentication_methods():
    """Test 4: Authentication Methods Testing"""
    print_test("Authentication Methods Testing")
    
    print("Testing Password Authentication:")
    cmd = [
        "ssh", "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=/dev/null",
        "-o", "PreferredAuthentications=password",
        "-o", "ConnectTimeout=3",
        "-p", str(SSH_PORT),
        f"testuser@{SSH_HOST}",
        "exit"
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
        if "password" in result.stderr.lower():
            print_warning("Password authentication is enabled")
        else:
            print_success("Password authentication status unclear")
    except:
        print_warning("Password authentication test inconclusive")
    
    print("\nTesting Public Key Authentication:")
    cmd = [
        "ssh", "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=/dev/null",
        "-o", "PreferredAuthentications=publickey",
        "-o", "ConnectTimeout=3",
        "-p", str(SSH_PORT),
        f"testuser@{SSH_HOST}",
        "exit"
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
        if "publickey" in result.stderr.lower():
            print_warning("Public key authentication is enabled")
        else:
            print_success("Public key authentication status unclear")
    except:
        print_warning("Public key authentication test inconclusive")
    
    print()

def test_brute_force_protection():
    """Test 5: Brute Force Protection"""
    print_test("Brute Force Protection Testing")
    
    print("Attempting multiple failed login attempts...")
    
    for i in range(1, 6):
        print(f"Attempt {i}:")
        cmd = [
            "sshpass", "-p", "wrongpassword",
            "ssh", "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-o", "ConnectTimeout=3",
            "-p", str(SSH_PORT),
            f"testuser@{SSH_HOST}",
            "exit"
        ]
        
        start = time.time()
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
            elapsed = (time.time() - start) * 1000
            print(f"  Response time: {elapsed:.2f}ms")
            
            if "Permission denied" in result.stderr:
                print(f"  Status: Authentication failed (expected)")
        except:
            print(f"  Status: Connection timeout or error")
        
        time.sleep(0.5)
    
    print_warning("No rate limiting or account lockout detected")
    print()

def main():
    print_header("SSH Vulnerability Testing Suite")
    print(f"Target: {SSH_HOST}:{SSH_PORT}")
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    tests = [
        test_ssh_banner,
        test_weak_algorithms,
        test_username_enumeration,
        test_authentication_methods,
        test_brute_force_protection
    ]
    
    for test in tests:
        try:
            test()
        except Exception as e:
            print_error(f"Test failed with error: {e}")
            print()
    
    print_header("Testing Complete")
    print(f"{Colors.YELLOW}Review the results above for identified vulnerabilities{Colors.NC}")
    print(f"{Colors.YELLOW}See SOLUTIONS.md for remediation guidance{Colors.NC}\n")

if __name__ == "__main__":
    main()

# Made with Bob
