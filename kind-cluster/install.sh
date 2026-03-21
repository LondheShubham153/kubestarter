#!/bin/bash
set -e          # Exit immediately if a command exits with a non-zero status
set -o pipefail # Catch failures inside pipes too

echo "🚀 Starting installation of Docker, Kind, and kubectl..."

# ----------------------------
# 1. Install Docker
# ----------------------------
if ! command -v docker &>/dev/null; then
  echo "📦 Installing Docker..."
  sudo apt-get update -y
  sudo apt-get install -y docker.io

  # Guard systemctl — not available in all environments (e.g. WSL, containers)
  if command -v systemctl &>/dev/null && [ -d /run/systemd/system ]; then
    sudo systemctl enable --now docker
  else
    echo "⚠️  Docker installed, but systemd is not available here. Start the daemon with your environment's service manager."
  fi

  echo "👤 Adding current user to docker group..."
  sudo usermod -aG docker "$USER"
  echo "⚠️  Run 'newgrp docker' or re-login for group changes to take effect."
  echo "✅ Docker installed and user added to docker group."
else
  echo "✅ Docker is already installed."
fi

# ----------------------------
# 2. Install Kind (latest version, based on architecture)
# ----------------------------
if ! command -v kind &>/dev/null; then
  echo "📦 Installing Kind..."

  if ! KIND_VERSION="$(
    curl -fsSL https://api.github.com/repos/kubernetes-sigs/kind/releases/latest \
      | grep '"tag_name"' \
      | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'
  )"; then
    echo "❌ Failed to fetch Kind version. Check your internet connection."
    exit 1
  elif [ -z "$KIND_VERSION" ]; then
    echo "❌ Failed to parse Kind version."
    exit 1
  fi

  case "$(uname -m)" in
    x86_64)           ARCH="amd64" ;;
    aarch64 | arm64)  ARCH="arm64" ;;
    *) echo "❌ Unsupported architecture: $(uname -m)"; exit 1 ;;
  esac

  curl -fsSLo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}"
  curl -fsSLo ./kind.sha256sum "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}.sha256sum"
  sha256sum --check --status ./kind.sha256sum || { echo "❌ Kind checksum failed!"; rm -f ./kind ./kind.sha256sum; exit 1; }
  rm -f ./kind.sha256sum
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/kind
  echo "✅ Kind ${KIND_VERSION} installed successfully."
else
  echo "✅ Kind is already installed."
fi

# ----------------------------
# 3. Install kubectl (based on architecture)
# ----------------------------
if ! command -v kubectl &>/dev/null; then
  echo "📦 Installing kubectl (latest stable version)..."

  if ! VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"; then
    echo "❌ Failed to fetch kubectl version. Check your internet connection."
    exit 1
  elif [ -z "$VERSION" ]; then
    echo "❌ Failed to parse kubectl version."
    exit 1
  fi

  case "$(uname -m)" in
    x86_64)           ARCH="amd64" ;;
    aarch64 | arm64)  ARCH="arm64" ;;
    *) echo "❌ Unsupported architecture: $(uname -m)"; exit 1 ;;
  esac

  curl -fsSLo ./kubectl "https://dl.k8s.io/release/${VERSION}/bin/linux/${ARCH}/kubectl"
  curl -fsSLo ./kubectl.sha256 "https://dl.k8s.io/release/${VERSION}/bin/linux/${ARCH}/kubectl.sha256"
  echo "$(cat ./kubectl.sha256)  ./kubectl" | sha256sum --check --status || { echo "❌ kubectl checksum failed!"; rm -f ./kubectl ./kubectl.sha256; exit 1; }
  rm -f ./kubectl.sha256
  chmod +x ./kubectl
  sudo mv ./kubectl /usr/local/bin/kubectl
  echo "✅ kubectl installed successfully."
else
  echo "✅ kubectl is already installed."
fi

# ----------------------------
# 4. Confirm Versions
# ----------------------------
echo
echo "🔍 Installed Versions:"
docker --version
kind --version
kubectl version --client --output=yaml
echo
echo "🎉 Docker, Kind, and kubectl installation complete!"
