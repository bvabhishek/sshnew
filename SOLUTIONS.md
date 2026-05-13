# SSH Security Solutions and Remediation Guide

This document provides comprehensive solutions to fix all SSH vulnerabilities identified in the vulnerable SSH server.

## Table of Contents
1. [Quick Fix Summary](#quick-fix-summary)
2. [Secure SSH Configuration](#secure-ssh-configuration)
3. [Detailed Remediation Steps](#detailed-remediation-steps)
4. [Hardening Checklist](#hardening-checklist)
5. [Monitoring and Maintenance](#monitoring-and-maintenance)

---

## Quick Fix Summary

| Vulnerability | Solution | Priority |
|--------------|----------|----------|
| SSHv1 Protocol Support | Disable SSHv1, use only SSHv2 | CRITICAL |
| Weak Ciphers | Use modern ciphers (AES-GCM, ChaCha20) | HIGH |
| Weak MACs | Use strong MACs (SHA2-256, SHA2-512) | HIGH |
| Weak Key Exchange | Use modern KEX (Curve25519, ECDH) | HIGH |
| Username Enumeration | Implement constant-time authentication | MEDIUM |
| Password Authentication | Disable or restrict with strong policies | HIGH |
| Root Login | Disable root login | HIGH |
| Weak Host Keys | Generate strong keys (RSA 4096, Ed25519) | HIGH |
| No Rate Limiting | Implement fail2ban and MaxAuthTries | MEDIUM |
| No 2FA | Enable two-factor authentication | MEDIUM |

---

## Secure SSH Configuration

### Complete Secure sshd_config

Create a secure SSH configuration file:

```bash
# /etc/ssh/sshd_config - Secure Configuration

# ============================================
# Protocol and Host Keys
# ============================================
Protocol 2                                    # Only SSHv2
Port 22                                       # Change to non-standard port if desired

# Use strong host keys only
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key

# ============================================
# Cryptographic Algorithms
# ============================================

# Strong Ciphers (AES-GCM and ChaCha20-Poly1305)
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

# Strong MACs (SHA2-256 and SHA2-512)
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256

# Strong Key Exchange Algorithms
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512

# ============================================
# Authentication
# ============================================

# Disable root login
PermitRootLogin no

# Disable password authentication (use keys only)
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# Enable public key authentication
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Limit authentication attempts
MaxAuthTries 3
MaxSessions 2

# Authentication timeout
LoginGraceTime 30

# ============================================
# User Access Control
# ============================================

# Allow specific users only (uncomment and customize)
# AllowUsers user1 user2 user3
# AllowGroups sshusers

# Deny specific users (uncomment and customize)
# DenyUsers root admin guest
# DenyGroups noremote

# ============================================
# Security Features
# ============================================

# Disable X11 forwarding
X11Forwarding no

# Disable TCP forwarding if not needed
AllowTcpForwarding no
AllowStreamLocalForwarding no

# Disable agent forwarding
AllowAgentForwarding no

# Disable tunneling
PermitTunnel no

# Disable gateway ports
GatewayPorts no

# ============================================
# Logging and Monitoring
# ============================================

# Verbose logging
SyslogFacility AUTH
LogLevel VERBOSE

# ============================================
# PAM and Environment
# ============================================

UsePAM yes
UseDNS no
PrintMotd no
PrintLastLog yes

# Disable environment processing
PermitUserEnvironment no

# ============================================
# Session Settings
# ============================================

# Client alive interval (disconnect idle sessions)
ClientAliveInterval 300
ClientAliveCountMax 2

# TCP keep alive
TCPKeepAlive yes

# Compression (disable for security)
Compression no

# ============================================
# Subsystems
# ============================================

# SFTP subsystem (chroot if needed)
Subsystem sftp /usr/lib/openssh/sftp-server

# ============================================
# Additional Hardening
# ============================================

# Strict modes
StrictModes yes

# Disable host-based authentication
HostbasedAuthentication no
IgnoreRhosts yes

# Banner (optional - can reveal info)
# Banner /etc/ssh/banner.txt
```

---

## Detailed Remediation Steps

### 1. Fix SSHv1 Protocol Support

**Problem:** Server accepts SSHv1 connections

**Solution:**

```bash
# Edit SSH configuration
sudo nano /etc/ssh/sshd_config

# Change from:
Protocol 2,1

# To:
Protocol 2

# Restart SSH service
sudo systemctl restart sshd
```

**Verification:**
```bash
# Check configuration
grep "^Protocol" /etc/ssh/sshd_config

# Test connection (should fail with SSHv1)
ssh -1 -p 22 user@server
# Expected: Protocol major versions differ
```

---

### 2. Fix Weak Encryption Algorithms

**Problem:** Server supports weak ciphers, MACs, and key exchange algorithms

**Solution:**

```bash
# Edit SSH configuration
sudo nano /etc/ssh/sshd_config

# Add strong algorithms only
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256

KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512

# Restart SSH service
sudo systemctl restart sshd
```

**Verification:**
```bash
# Test weak cipher (should fail)
ssh -c 3des-cbc -p 22 user@server
# Expected: no matching cipher found

# Test weak MAC (should fail)
ssh -m hmac-md5 -p 22 user@server
# Expected: no matching MAC found

# Scan with ssh-audit
ssh-audit server
```

---

### 3. Fix Username Enumeration

**Problem:** Timing differences reveal valid usernames

**Solution:**

```bash
# Edit SSH configuration
sudo nano /etc/ssh/sshd_config

# Reduce timing differences
UsePAM yes
LoginGraceTime 30

# Implement fail2ban for rate limiting
sudo apt-get install fail2ban

# Configure fail2ban
sudo nano /etc/fail2ban/jail.local
```

**fail2ban Configuration:**
```ini
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
```

**Additional Hardening:**
```bash
# Install and configure pam_shield (delays authentication)
sudo apt-get install libpam-shield

# Edit PAM configuration
sudo nano /etc/pam.d/sshd

# Add before @include common-auth:
auth required pam_shield.so
```

**Verification:**
```bash
# Monitor fail2ban
sudo fail2ban-client status sshd

# Test timing (should be more consistent)
time ssh user@server
time ssh fakeuser@server
```

---

### 4. Disable Password Authentication

**Problem:** Password authentication vulnerable to brute-force

**Solution:**

```bash
# Generate SSH key pair (if not exists)
ssh-keygen -t ed25519 -C "user@email.com"
# Or for RSA:
ssh-keygen -t rsa -b 4096 -C "user@email.com"

# Copy public key to server
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server

# Edit SSH configuration on server
sudo nano /etc/ssh/sshd_config

# Disable password authentication
PasswordAuthentication no
ChallengeResponseAuthentication no
PermitEmptyPasswords no

# Enable public key authentication
PubkeyAuthentication yes

# Restart SSH service
sudo systemctl restart sshd
```

**Verification:**
```bash
# Test key-based login (should work)
ssh -i ~/.ssh/id_ed25519 user@server

# Test password login (should fail)
ssh -o PreferredAuthentications=password user@server
# Expected: Permission denied
```

---

### 5. Disable Root Login

**Problem:** Direct root access increases risk

**Solution:**

```bash
# Edit SSH configuration
sudo nano /etc/ssh/sshd_config

# Disable root login
PermitRootLogin no

# Restart SSH service
sudo systemctl restart sshd

# Create sudo user for administrative tasks
sudo adduser adminuser
sudo usermod -aG sudo adminuser
```

**Verification:**
```bash
# Test root login (should fail)
ssh root@server
# Expected: Permission denied

# Test sudo access
ssh adminuser@server
sudo whoami
# Expected: root
```

---

### 6. Generate Strong Host Keys

**Problem:** Weak 1024-bit RSA and DSA keys

**Solution:**

```bash
# Backup old keys
sudo mkdir /etc/ssh/old_keys
sudo mv /etc/ssh/ssh_host_* /etc/ssh/old_keys/

# Generate new strong keys
sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
sudo ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""

# Update SSH configuration
sudo nano /etc/ssh/sshd_config

# Use only strong keys
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key

# Remove weak key references
# (Delete lines for DSA and ECDSA if present)

# Restart SSH service
sudo systemctl restart sshd
```

**Verification:**
```bash
# Check key strength
ssh-keygen -l -f /etc/ssh/ssh_host_rsa_key.pub
# Expected: 4096 SHA256:...

ssh-keygen -l -f /etc/ssh/ssh_host_ed25519_key.pub
# Expected: 256 SHA256:...

# Test connection
ssh user@server
# Check for new host key warning
```

---

### 7. Implement Rate Limiting

**Problem:** No protection against brute-force attacks

**Solution:**

```bash
# Edit SSH configuration
sudo nano /etc/ssh/sshd_config

# Limit authentication attempts
MaxAuthTries 3
MaxSessions 2
LoginGraceTime 30

# Install fail2ban
sudo apt-get install fail2ban

# Configure fail2ban
sudo nano /etc/fail2ban/jail.local
```

**fail2ban Configuration:**
```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
banaction = iptables-multiport

[sshd-ddos]
enabled = true
port = ssh
filter = sshd-ddos
logpath = /var/log/auth.log
maxretry = 10
findtime = 60
bantime = 600
```

**Start fail2ban:**
```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo fail2ban-client status
```

**Verification:**
```bash
# Test rate limiting
for i in {1..5}; do
    ssh -o PreferredAuthentications=password wronguser@server
done

# Check fail2ban status
sudo fail2ban-client status sshd

# Check banned IPs
sudo fail2ban-client get sshd banned
```

---

### 8. Enable Two-Factor Authentication

**Problem:** Single-factor authentication is less secure

**Solution:**

```bash
# Install Google Authenticator PAM module
sudo apt-get install libpam-google-authenticator

# Configure for user
google-authenticator
# Answer: Yes to all questions
# Save emergency codes

# Edit PAM configuration
sudo nano /etc/pam.d/sshd

# Add at the top:
auth required pam_google_authenticator.so

# Edit SSH configuration
sudo nano /etc/ssh/sshd_config

# Enable challenge-response
ChallengeResponseAuthentication yes

# Configure authentication methods
AuthenticationMethods publickey,keyboard-interactive

# Restart SSH service
sudo systemctl restart sshd
```

**Verification:**
```bash
# Test login (should prompt for verification code)
ssh user@server
# Expected: Verification code: _____
```

---

### 9. Implement IP Restrictions

**Problem:** No IP-based access control

**Solution:**

```bash
# Edit SSH configuration
sudo nano /etc/ssh/sshd_config

# Allow specific users from specific IPs
Match User adminuser Address 192.168.1.0/24
    PasswordAuthentication no
    PubkeyAuthentication yes

Match User developer Address 10.0.0.0/8
    PasswordAuthentication no
    AllowTcpForwarding yes

# Deny all others
Match User *
    DenyUsers *

# Or use AllowUsers with specific IPs
AllowUsers user1@192.168.1.* user2@10.0.0.*

# Restart SSH service
sudo systemctl restart sshd
```

**Using TCP Wrappers:**
```bash
# Edit /etc/hosts.allow
sudo nano /etc/hosts.allow

# Add:
sshd: 192.168.1.0/24
sshd: 10.0.0.0/8

# Edit /etc/hosts.deny
sudo nano /etc/hosts.deny

# Add:
sshd: ALL
```

**Verification:**
```bash
# Test from allowed IP (should work)
ssh user@server

# Test from denied IP (should fail)
# Expected: Connection refused or timeout
```

---

### 10. Configure Logging and Monitoring

**Problem:** Insufficient logging and monitoring

**Solution:**

```bash
# Edit SSH configuration
sudo nano /etc/ssh/sshd_config

# Enable verbose logging
LogLevel VERBOSE
SyslogFacility AUTH

# Restart SSH service
sudo systemctl restart sshd

# Configure rsyslog for centralized logging
sudo nano /etc/rsyslog.d/50-default.conf

# Add:
auth,authpriv.* /var/log/auth.log
auth,authpriv.* @@logserver:514

# Install and configure auditd
sudo apt-get install auditd

# Add SSH audit rules
sudo nano /etc/audit/rules.d/ssh.rules
```

**SSH Audit Rules:**
```bash
# Monitor SSH configuration changes
-w /etc/ssh/sshd_config -p wa -k sshd_config

# Monitor SSH key files
-w /etc/ssh/ -p wa -k ssh_keys

# Monitor user SSH directories
-w /home/ -p wa -k ssh_user_keys

# Monitor SSH daemon
-w /usr/sbin/sshd -p x -k sshd_execution
```

**Restart auditd:**
```bash
sudo systemctl restart auditd
```

**Monitoring Script:**
```bash
#!/bin/bash
# ssh_monitor.sh

# Monitor failed login attempts
echo "=== Failed Login Attempts ==="
grep "Failed password" /var/log/auth.log | tail -20

# Monitor successful logins
echo -e "\n=== Successful Logins ==="
grep "Accepted" /var/log/auth.log | tail -20

# Monitor authentication errors
echo -e "\n=== Authentication Errors ==="
grep "authentication failure" /var/log/auth.log | tail -20

# Check for brute force attempts
echo -e "\n=== Potential Brute Force ==="
grep "Failed password" /var/log/auth.log | \
    awk '{print $11}' | sort | uniq -c | sort -rn | head -10
```

---

## Hardening Checklist

### Pre-Deployment Checklist

- [ ] Disable SSHv1 protocol
- [ ] Configure strong ciphers, MACs, and KEX algorithms
- [ ] Generate strong host keys (Ed25519, RSA 4096)
- [ ] Disable root login
- [ ] Disable password authentication
- [ ] Enable public key authentication only
- [ ] Configure MaxAuthTries and LoginGraceTime
- [ ] Install and configure fail2ban
- [ ] Enable two-factor authentication
- [ ] Implement IP-based access control
- [ ] Configure verbose logging
- [ ] Set up log monitoring and alerting
- [ ] Change default SSH port (optional)
- [ ] Disable unnecessary features (X11, TCP forwarding)
- [ ] Configure client alive intervals
- [ ] Test configuration before deployment

### Post-Deployment Checklist

- [ ] Verify SSHv1 is disabled
- [ ] Test weak algorithm rejection
- [ ] Verify key-based authentication works
- [ ] Verify password authentication is disabled
- [ ] Test root login is blocked
- [ ] Verify fail2ban is working
- [ ] Test 2FA functionality
- [ ] Verify IP restrictions
- [ ] Check log files are being generated
- [ ] Set up automated security scans
- [ ] Document all changes
- [ ] Train users on new authentication methods
- [ ] Create incident response procedures
- [ ] Schedule regular security audits

---

## Monitoring and Maintenance

### Regular Security Scans

```bash
# Weekly SSH security scan
ssh-audit server > /var/log/ssh-audit-$(date +%Y%m%d).log

# Monthly vulnerability scan
nmap -p 22 --script ssh-auth-methods,ssh-hostkey,ssh2-enum-algos server

# Check for updates
sudo apt-get update
sudo apt-get upgrade openssh-server
```

### Log Analysis

```bash
# Daily log review
sudo grep "Failed\|Accepted" /var/log/auth.log | tail -100

# Weekly summary
sudo journalctl -u sshd --since "1 week ago" | grep -E "Failed|Accepted"

# Check fail2ban statistics
sudo fail2ban-client status sshd
```

### Automated Monitoring

Create a cron job for automated monitoring:

```bash
# Edit crontab
crontab -e

# Add daily security check
0 2 * * * /usr/local/bin/ssh_security_check.sh

# Add weekly audit
0 3 * * 0 /usr/local/bin/ssh_weekly_audit.sh
```

**ssh_security_check.sh:**
```bash
#!/bin/bash
# Daily SSH security check

LOG_FILE="/var/log/ssh_security_check.log"
DATE=$(date +"%Y-%m-%d %H:%M:%S")

echo "[$DATE] SSH Security Check" >> $LOG_FILE

# Check for failed logins
FAILED=$(grep "Failed password" /var/log/auth.log | wc -l)
echo "Failed login attempts: $FAILED" >> $LOG_FILE

# Check for successful logins
SUCCESS=$(grep "Accepted" /var/log/auth.log | wc -l)
echo "Successful logins: $SUCCESS" >> $LOG_FILE

# Check fail2ban status
BANNED=$(sudo fail2ban-client status sshd | grep "Currently banned" | awk '{print $4}')
echo "Currently banned IPs: $BANNED" >> $LOG_FILE

# Alert if threshold exceeded
if [ $FAILED -gt 100 ]; then
    echo "ALERT: High number of failed login attempts!" >> $LOG_FILE
    # Send email alert
    echo "High SSH failed login attempts: $FAILED" | mail -s "SSH Security Alert" admin@example.com
fi

echo "---" >> $LOG_FILE
```

---

## Secure Docker Configuration

### Dockerfile for Secure SSH Server

```dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install SSH server
RUN apt-get update && \
    apt-get install -y \
    openssh-server \
    fail2ban \
    && rm -rf /var/lib/apt/lists/*

# Create SSH directory
RUN mkdir /var/run/sshd

# Generate strong host keys
RUN rm -f /etc/ssh/ssh_host_* && \
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N '' && \
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ''

# Copy secure SSH configuration
COPY sshd_config_secure /etc/ssh/sshd_config

# Create non-root user
RUN useradd -m -s /bin/bash sshuser && \
    mkdir -p /home/sshuser/.ssh && \
    chmod 700 /home/sshuser/.ssh && \
    chown -R sshuser:sshuser /home/sshuser/.ssh

# Copy authorized keys
COPY authorized_keys /home/sshuser/.ssh/authorized_keys
RUN chmod 600 /home/sshuser/.ssh/authorized_keys && \
    chown sshuser:sshuser /home/sshuser/.ssh/authorized_keys

# Configure fail2ban
COPY jail.local /etc/fail2ban/jail.local

# Expose SSH port
EXPOSE 22

# Start services
CMD service fail2ban start && /usr/sbin/sshd -D
```

---

## Testing Secure Configuration

### Verification Script

```bash
#!/bin/bash
# verify_secure_ssh.sh

echo "=== SSH Security Verification ==="

# Test 1: SSHv1 should be disabled
echo -e "\n[1] Testing SSHv1 (should fail):"
timeout 3 ssh -1 -p 22 user@server 2>&1 | grep -i "protocol"

# Test 2: Weak ciphers should be rejected
echo -e "\n[2] Testing weak cipher (should fail):"
timeout 3 ssh -c 3des-cbc -p 22 user@server 2>&1 | grep -i "cipher"

# Test 3: Password auth should be disabled
echo -e "\n[3] Testing password auth (should fail):"
timeout 3 ssh -o PreferredAuthentications=password -p 22 user@server 2>&1 | grep -i "permission"

# Test 4: Root login should be disabled
echo -e "\n[4] Testing root login (should fail):"
timeout 3 ssh root@server 2>&1 | grep -i "permission"

# Test 5: Key-based auth should work
echo -e "\n[5] Testing key-based auth (should succeed):"
ssh -i ~/.ssh/id_ed25519 -p 22 user@server "echo 'Key auth successful'"

# Test 6: Check fail2ban status
echo -e "\n[6] Checking fail2ban:"
sudo fail2ban-client status sshd

echo -e "\n=== Verification Complete ==="
```

---

## References and Resources

- [OpenSSH Security Best Practices](https://www.openssh.com/security.html)
- [Mozilla SSH Guidelines](https://infosec.mozilla.org/guidelines/openssh)
- [CIS Benchmark for SSH](https://www.cisecurity.org/)
- [NIST SSH Guidelines](https://csrc.nist.gov/)
- [ssh-audit Tool](https://github.com/jtesta/ssh-audit)
- [fail2ban Documentation](https://www.fail2ban.org/)

---

## Support and Updates

For the latest security updates and patches:
- Subscribe to OpenSSH security mailing list
- Monitor CVE databases
- Regular security audits
- Keep systems updated

---

**Last Updated:** 2026-05-13  
**Version:** 1.0