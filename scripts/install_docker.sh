#!/bin/bash

# Remove any old Docker versions
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    sudo apt-get remove -y $pkg 
done

# System update & install dependencies
sudo apt update -y
sudo apt install -y ca-certificates curl gnupg

# Setup Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repo to apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
sudo apt update -y

# Install Docker components (Compose V2 included)
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker and enable it on boot
sudo systemctl start docker
sudo systemctl enable docker


# Add current user to docker group 
sudo usermod -aG docker $USER
cd /home/ubuntu
# Install jq for JSON parsing
sudo apt-get install -y jq
# Install AWS CLI
sudo snap install aws-cli --classic

SECRET_NAME="prod/live/degeneral-secret"
REGION="eu-west-1"

# Get secret value
SECRET_JSON=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    --query SecretString \
    --output text)


# Parse and export each variable
export DB_HOST=$(echo $SECRET_JSON | jq -r '.DB_HOST')
export DB_USER=$(echo $SECRET_JSON | jq -r '.DB_USER')
export DB_PASS=$(echo $SECRET_JSON | jq -r '.DB_PASS')
export DB_NAME=$(echo $SECRET_JSON | jq -r '.DB_NAME')

echo $DB_HOST
echo $DB_USER
echo $DB_PASS
echo $DB_NAME

# Optional: print to confirm
echo "Environment variables set..."

sudo docker pull degeneral1/lamp-app

sudo docker run -d \
  --name lamp-app \
  -p 80:80 \
  -e DB_HOST=$DB_HOST \
  -e DB_USER=$DB_USER \
  -e DB_PASS=$DB_PASS \
  -e DB_NAME=$DB_NAME \
  degeneral1/lamp-app

