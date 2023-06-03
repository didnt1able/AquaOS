#!/usr/bin/env bash

# Enable password authentication for SSH
echo 'PasswordAuthentication yes' | sudo tee /etc/ssh/sshd_config.d/02-enable-passwords.conf

# Restart SSH service
sudo systemctl try-restart sshd

# Run the cockpit-ws container
podman container runlabel --name cockpit-ws RUN quay.io/cockpit/ws

# Run the cockpit-ws container with INSTALL label
podman container runlabel INSTALL quay.io/cockpit/ws

# Enable cockpit service
sudo systemctl enable cockpit.service
