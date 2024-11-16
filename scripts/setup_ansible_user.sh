#!/bin/bash

# This script creates the ansible user in the VM and sets up necessary permissions

# Create ansible user if it doesn't exist
if ! id "ansible" &>/dev/null; then
    useradd -m -s /bin/bash ansible
fi

# Set up sudo access for ansible user
echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible
chmod 0440 /etc/sudoers.d/ansible

# Create .ssh directory for ansible user
mkdir -p /home/ansible/.ssh
chmod 700 /home/ansible/.ssh

# Copy authorized_keys from current user if it exists
if [ -f "$HOME/.ssh/authorized_keys" ]; then
    cp "$HOME/.ssh/authorized_keys" /home/ansible/.ssh/
    chmod 600 /home/ansible/.ssh/authorized_keys
    chown -R ansible:ansible /home/ansible/.ssh
fi
