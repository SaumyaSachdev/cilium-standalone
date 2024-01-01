#!/bin/bash

# Update package information
sudo apt-get update

# Install required packages
sudo apt-get install -y ca-certificates curl gnupg

# Create directory for keyrings
sudo install -m 0755 -d /etc/apt/keyrings

# Download Docker GPG key and save it to /etc/apt/keyrings/docker.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set permissions for the GPG key
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository to Apt sources
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package information again
sudo apt-get update

# Install Docker packages
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo docker run hello-world

echo "Docker has been successfully installed."
