FROM ubuntu:20.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install SSH server and necessary tools
RUN apt-get update && \
    apt-get install -y \
    openssh-server \
    vim \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Create SSH directory
RUN mkdir /var/run/sshd

# Configure SSH for vulnerabilities
RUN mkdir -p /etc/ssh/sshd_config.d/

# Create vulnerable SSH configuration
RUN echo "# Vulnerable SSH Configuration" > /etc/ssh/sshd_config && \
    echo "Port 22" >> /etc/ssh/sshd_config && \
    echo "Protocol 2" >> /etc/ssh/sshd_config && \
    echo "" >> /etc/ssh/sshd_config && \
    echo "# Authentication" >> /etc/ssh/sshd_config && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config && \
    echo "" >> /etc/ssh/sshd_config && \
    echo "# Weak Ciphers and MACs" >> /etc/ssh/sshd_config && \
    echo "Ciphers aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc" >> /etc/ssh/sshd_config && \
    echo "MACs hmac-md5,hmac-sha1,hmac-ripemd160" >> /etc/ssh/sshd_config && \
    echo "KexAlgorithms diffie-hellman-group1-sha1,diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1" >> /etc/ssh/sshd_config && \
    echo "" >> /etc/ssh/sshd_config && \
    echo "# Timing attack vulnerability" >> /etc/ssh/sshd_config && \
    echo "UsePAM yes" >> /etc/ssh/sshd_config && \
    echo "LoginGraceTime 120" >> /etc/ssh/sshd_config && \
    echo "" >> /etc/ssh/sshd_config && \
    echo "# Logging" >> /etc/ssh/sshd_config && \
    echo "SyslogFacility AUTH" >> /etc/ssh/sshd_config && \
    echo "LogLevel INFO" >> /etc/ssh/sshd_config

# Create test users with weak passwords
RUN useradd -m -s /bin/bash testuser && \
    echo 'testuser:password123' | chpasswd && \
    useradd -m -s /bin/bash admin && \
    echo 'admin:admin' | chpasswd && \
    useradd -m -s /bin/bash user1 && \
    echo 'user1:user1' | chpasswd && \
    useradd -m -s /bin/bash validuser && \
    echo 'validuser:ValidPass123!' | chpasswd

# Create SSH directory for users
RUN mkdir -p /home/testuser/.ssh && \
    mkdir -p /home/admin/.ssh && \
    mkdir -p /home/user1/.ssh && \
    mkdir -p /home/validuser/.ssh

# Generate SSH keys for public key authentication testing
RUN ssh-keygen -t rsa -b 2048 -f /home/testuser/.ssh/id_rsa -N '' && \
    cat /home/testuser/.ssh/id_rsa.pub > /home/testuser/.ssh/authorized_keys && \
    chown -R testuser:testuser /home/testuser/.ssh && \
    chmod 700 /home/testuser/.ssh && \
    chmod 600 /home/testuser/.ssh/authorized_keys

# Set root password for testing
RUN echo 'root:toor' | chpasswd

# Expose SSH port
EXPOSE 22

# Start SSH service
CMD ["/usr/sbin/sshd", "-D", "-e"]

# Made with Bob
