# Base CentOS image with SSH and common tools
FROM centos:7

# Fix CentOS 7 EOL repository issues
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo

# Install EPEL repository and common tools
RUN yum install -y epel-release && \
    yum update -y && \
    yum install -y \
        # SSH Server
        openssh-server \
        openssh-clients \
        # Basic utilities
        vim \
        nano \
        less \
        which \
        file \
        tree \
        # Network tools
        curl \
        wget \
        net-tools \
        bind-utils \
        tcpdump \
        nmap-ncat \
        telnet \
        iproute \
        iptables \
        # System monitoring
        htop \
        sysstat \
        iotop \
        lsof \
        strace \
        # Process management
        procps-ng \
        psmisc \
        # Log tools
        lnav \
        multitail \
        # Misc
        sudo \
        passwd \
        cronie \
        rsync \
        tar \
        gzip \
        unzip \
    && yum clean all

# Configure SSH
RUN ssh-keygen -A && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

# Create SSH keys for ansible access
RUN ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N "" -C "ansible@copilot-infra"

# Copy public key to authorized_keys (will be overwritten by ansible-control's key)
RUN cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys

# Configure SSH to allow root login
RUN sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Install node_exporter for Prometheus monitoring
RUN curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz && \
    tar xzf node_exporter-1.6.1.linux-amd64.tar.gz && \
    mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/ && \
    rm -rf node_exporter-1.6.1.linux-amd64*

# Create node_exporter user
RUN useradd -rs /bin/false node_exporter

# Create systemd-like startup script for node_exporter
RUN echo '#!/bin/bash' > /usr/local/bin/start-node-exporter.sh && \
    echo '/usr/local/bin/node_exporter --web.listen-address=:9100 &' >> /usr/local/bin/start-node-exporter.sh && \
    chmod +x /usr/local/bin/start-node-exporter.sh

# Create entrypoint script
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Start SSH daemon' >> /entrypoint.sh && \
    echo '/usr/sbin/sshd' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Start node_exporter' >> /entrypoint.sh && \
    echo '/usr/local/bin/start-node-exporter.sh' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Execute any additional command or keep container running' >> /entrypoint.sh && \
    echo 'exec "$@"' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Add helpful aliases and environment
RUN echo 'alias ll="ls -la"' >> /root/.bashrc && \
    echo 'alias la="ls -la"' >> /root/.bashrc && \
    echo 'alias ports="ss -tlnp"' >> /root/.bashrc && \
    echo 'alias logs="journalctl -f"' >> /root/.bashrc && \
    echo 'export PS1="[\u@\h \W]\\$ "' >> /root/.bashrc

# Expose SSH and node_exporter ports
EXPOSE 22 9100

ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
