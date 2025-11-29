#!/bin/bash

set -e

echo "Starting Minikube Installation on Ubuntu..."

# ----------------------------
# 1. Update System Packages
# ----------------------------
echo "Updating apt package list..."
sudo apt update -y


# ----------------------------
# 2. Install Required Packages
# ----------------------------
echo "Installing curl, wget, apt-transport-https..."
sudo apt install -y curl wget apt-transport-https


# ----------------------------
# 3. Install Docker (Minikube driver)
# ----------------------------
if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  sudo apt install -y docker.io

  echo "Enabling and starting Docker..."
  sudo systemctl enable --now docker

  echo "Adding current user to Docker group..."
  sudo usermod -aG docker "$USER"
  echo "Please log out and log back in OR run: newgrp docker"
else
  echo "Docker is already installed."
fi


# ----------------------------
# 4. Install Minikube (based on architecture)
# ----------------------------
if ! command -v minikube &>/dev/null; then
  echo "Installing Minikube..."

  ARCH=$(uname -m)
  if [ "$ARCH" = "x86_64" ]; then
    URL="https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
  elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    URL="https://storage.googleapis.com/minikube/releases/latest/minikube-linux-arm64"
  else
    echo "Unsupported architecture: $ARCH"
    exit 1
  fi

  curl -Lo minikube "$URL"
  chmod +x minikube
  sudo mv minikube /usr/local/bin/minikube

  echo "Minikube installed successfully."
else
  echo "Minikube is already installed."
fi


# ----------------------------
# 5. Install kubectl (based on architecture)
# ----------------------------
if ! command -v kubectl &>/dev/null; then
  echo "Installing kubectl (latest stable version)..."

  ARCH=$(uname -m)
  VERSION=$(curl -Ls https://dl.k8s.io/release/stable.txt)

  if [ "$ARCH" = "x86_64" ]; then
    curl -Lo kubectl "https://dl.k8s.io/release/${VERSION}/bin/linux/amd64/kubectl"
  elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    curl -Lo kubectl "https://dl.k8s.io/release/${VERSION}/bin/linux/arm64/kubectl"
  else
    echo "Unsupported architecture: $ARCH"
    exit 1
  fi

  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/kubectl

  echo "kubectl installed successfully."
else
  echo "kubectl is already installed."
fi


# ----------------------------
# 6. Start Minikube
# ----------------------------
echo "Starting Minikube cluster using Docker driver..."
minikube start --driver=docker --vm=true

echo "Minikube cluster started successfully!"


# ----------------------------
# 7. Show Cluster Status
# ----------------------------
echo "Checking Minikube status..."
minikube status

echo "Kubernetes nodes:"
kubectl get nodes


echo "Installation complete! You can now use Minikube + kubectl."
echo "To stop Minikube:   minikube stop"
echo "To delete cluster:   minikube delete"
