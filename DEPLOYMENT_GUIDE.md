# Deployment Guide for Remote Machine

## Quick Deployment on 9.30.123.170

The files are already on the remote machine at `/root/abhishek/sshnew/`. Follow these steps:

### Step 1: Connect to Remote Machine

```bash
ssh root@9.30.123.170
# Password: Mint@9876543210
```

### Step 2: Navigate to Project Directory

```bash
cd /root/abhishek/sshnew
```

### Step 3: Make Scripts Executable

```bash
chmod +x deploy_on_remote.sh test_vulnerabilities.sh advanced_tests.py
```

### Step 4: Deploy the Vulnerable SSH Server

```bash
./deploy_on_remote.sh
```

This script will:
- Clean up any existing containers
- Build the Docker image
- Start the vulnerable SSH server on port 2222
- Verify the deployment

### Step 5: Test the Deployment

#### From the Remote Machine (localhost):
```bash
# Test SSH connection
ssh -p 2222 testuser@localhost
# Password: password123

# Run vulnerability tests
./test_vulnerabilities.sh

# Run advanced tests
python3 advanced_tests.py
```

#### From Your Local Machine:
```bash
# Test SSH connection
ssh -p 2222 testuser@9.30.123.170
# Password: password123

# Test with weak cipher
ssh -c 3des-cbc -p 2222 testuser@9.30.123.170

# Test username enumeration
time ssh -p 2222 testuser@9.30.123.170
time ssh -p 2222 fakeuser@9.30.123.170
```

## Alternative: Manual Deployment

If the automated script doesn't work, follow these manual steps:

### 1. Clean Up Existing Containers

```bash
cd /root/abhishek/sshnew
docker stop vulnerable-ssh-server 2>/dev/null || true
docker rm vulnerable-ssh-server 2>/dev/null || true
docker rmi vulnerable-ssh-server 2>/dev/null || true
```

### 2. Build Docker Image

```bash
docker build -t vulnerable-ssh-server .
```

If you encounter the "Overwrite (y/n)?" error, the Dockerfile has been fixed to automatically remove existing SSH keys.

### 3. Run Container

```bash
docker run -d \
    --name vulnerable-ssh-server \
    -p 2222:22 \
    vulnerable-ssh-server
```

### 4. Verify Container is Running

```bash
docker ps | grep vulnerable-ssh-server
```

### 5. Check Logs

```bash
docker logs vulnerable-ssh-server
```

### 6. Test Connectivity

```bash
nc -zv localhost 2222
```

## Test Credentials

| Username | Password | Notes |
|----------|----------|-------|
| root | toor | Root access |
| testuser | password123 | Weak password |
| admin | admin | Very weak password |
| user1 | user1 | Username as password |
| validuser | ValidPass123! | Stronger password |

## Troubleshooting

### Issue: Docker build fails with "Overwrite (y/n)?"

**Solution:** The Dockerfile has been updated to remove existing SSH keys first. Rebuild:
```bash
docker build --no-cache -t vulnerable-ssh-server .
```

### Issue: Container won't start

**Solution:** Check logs and rebuild:
```bash
docker logs vulnerable-ssh-server
docker stop vulnerable-ssh-server
docker rm vulnerable-ssh-server
docker build --no-cache -t vulnerable-ssh-server .
docker run -d --name vulnerable-ssh-server -p 2222:22 vulnerable-ssh-server
```

### Issue: Port 2222 already in use

**Solution:** Find and stop the process using port 2222:
```bash
lsof -i :2222
# Or
netstat -tulpn | grep 2222

# Kill the process or use a different port
docker run -d --name vulnerable-ssh-server -p 2223:22 vulnerable-ssh-server
```

### Issue: Cannot connect to SSH

**Solution:** Verify container is running and port is accessible:
```bash
docker ps
docker logs vulnerable-ssh-server
nc -zv localhost 2222
```

## Container Management

### View Logs
```bash
docker logs -f vulnerable-ssh-server
```

### Access Container Shell
```bash
docker exec -it vulnerable-ssh-server /bin/bash
```

### Stop Container
```bash
docker stop vulnerable-ssh-server
```

### Remove Container
```bash
docker rm vulnerable-ssh-server
```

### Remove Image
```bash
docker rmi vulnerable-ssh-server
```

## Running Tests

### Basic Vulnerability Tests
```bash
cd /root/abhishek/sshnew
./test_vulnerabilities.sh
```

### Advanced Python Tests
```bash
cd /root/abhishek/sshnew
python3 advanced_tests.py
```

### Manual Testing Examples

#### Test SSHv1 Protocol
```bash
echo "SSH-1.5-TestClient" | nc localhost 2222
```

#### Test Weak Ciphers
```bash
ssh -c 3des-cbc -p 2222 testuser@localhost
ssh -c arcfour -p 2222 testuser@localhost
```

#### Test Weak MACs
```bash
ssh -m hmac-md5 -p 2222 testuser@localhost
```

#### Test Username Enumeration
```bash
time ssh -o PreferredAuthentications=password -p 2222 testuser@localhost
time ssh -o PreferredAuthentications=password -p 2222 fakeuser@localhost
```

#### Test Password Authentication
```bash
sshpass -p password123 ssh -p 2222 testuser@localhost "whoami"
```

#### Test Root Login
```bash
sshpass -p toor ssh -p 2222 root@localhost "whoami"
```

## Security Scanning

### Using ssh-audit
```bash
# Install ssh-audit if not available
pip3 install ssh-audit

# Scan the server
ssh-audit localhost -p 2222
```

### Using Nmap
```bash
nmap -p 2222 --script ssh-hostkey,ssh2-enum-algos localhost
```

## Accessing from External Networks

If you want to test from external networks, ensure:

1. Firewall allows port 2222:
```bash
# Check firewall status
firewall-cmd --list-all

# Add port if needed
firewall-cmd --permanent --add-port=2222/tcp
firewall-cmd --reload
```

2. Test from external machine:
```bash
ssh -p 2222 testuser@9.30.123.170
```

## Documentation

All documentation is available in the project directory:

- **README.md** - Complete project documentation
- **VULNERABILITIES.md** - Detailed vulnerability documentation
- **SOLUTIONS.md** - Remediation guide
- **PROJECT_SUMMARY.md** - Project overview

## Support

If you encounter issues:

1. Check the logs: `docker logs vulnerable-ssh-server`
2. Verify Docker is running: `docker ps`
3. Check port availability: `netstat -tulpn | grep 2222`
4. Review the troubleshooting section above
5. Rebuild with no cache: `docker build --no-cache -t vulnerable-ssh-server .`

## Important Reminders

⚠️ **WARNING:** This is a deliberately vulnerable SSH server for educational purposes only!

- DO NOT expose to the internet
- DO NOT use in production
- ONLY use in isolated lab environments
- This server contains critical security vulnerabilities

---

**Deployment Location:** `/root/abhishek/sshnew/` on 9.30.123.170  
**SSH Port:** 2222  
**Container Name:** vulnerable-ssh-server