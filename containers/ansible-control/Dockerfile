# Ansible Control Node
# Using AlmaLinux 8 for better ARM64 support while maintaining RHEL compatibility
FROM almalinux:8

# Install EPEL and packages
RUN dnf install -y epel-release && \
    dnf update -y && \
    dnf install -y \
        openssh-clients \
        vim nano less which file tree \
        curl wget net-tools bind-utils \
        python3 python3-pip \
        sshpass \
        git \
        nmap-ncat \
    && dnf clean all

# Install Ansible
RUN pip3 install --upgrade pip && \
    pip3 install ansible==2.10.7

# SSH keys will be mounted from shared-ssh directory
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

# Configure SSH client
RUN echo "Host *" > /tmp/ssh_config && \
    echo "    StrictHostKeyChecking no" >> /tmp/ssh_config && \
    echo "    UserKnownHostsFile /dev/null" >> /tmp/ssh_config && \
    echo "    LogLevel ERROR" >> /tmp/ssh_config && \
    chmod 600 /tmp/ssh_config

# Create entrypoint that distributes SSH keys
RUN cat > /entrypoint.sh << 'EOF'
#!/bin/bash
set -e

echo "Ansible Control Node starting..."

# Copy SSH config since /root/.ssh may be mounted read-only
cp /tmp/ssh_config /tmp/ssh_config_live
export SSH_CONFIG=/tmp/ssh_config_live

# Wait for all hosts to be ready
for host in frontend backend database; do
    echo "Waiting for $host to be ready..."
    retry=0
    max_retries=30
    while [ $retry -lt $max_retries ]; do
        if nc -z $host 22 2>/dev/null; then
            echo "$host is ready!"
            break
        fi
        retry=$((retry + 1))
        sleep 2
    done
    if [ $retry -eq $max_retries ]; then
        echo "Warning: Could not connect to $host"
    fi
done

echo "Ansible Control Node ready!"
echo "Run: ansible-playbook -i /ansible/inventory/hosts /ansible/playbooks/site.yml"

# Keep container running
exec "$@"
EOF
RUN chmod +x /entrypoint.sh

# Add helpful aliases
RUN echo 'alias ll="ls -la"' >> /root/.bashrc && \
    echo 'alias la="ls -la"' >> /root/.bashrc && \
    echo 'alias ap="ansible-playbook"' >> /root/.bashrc && \
    echo 'alias ai="ansible -i /ansible/inventory/hosts"' >> /root/.bashrc && \
    echo 'alias provision="ansible-playbook -i /ansible/inventory/hosts /ansible/playbooks/site.yml"' >> /root/.bashrc

WORKDIR /ansible

ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
