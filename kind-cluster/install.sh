#!/bin/bash
set -e          # Exit immediately if a command exits with a non-zero status
set -o pipefail # Catch errors in pipes

echo "🚀 Starting installation of Docker, Kind, and kubectl..."

# ----------------------------
# Helper: require curl
# ----------------------------
if ! command -v curl &>/dev/null; then
  echo "📦 Installing curl (required for downloads)..."
  sudo apt-get update -y
  sudo apt-get install -y curl
fi

# ----------------------------
# 1. Install Docker
# ----------------------------
if ! command -v docker &>/dev/null; then
  echo "📦 Installing Docker..."
  sudo apt-get update -y
  sudo apt-get install -y docker.io
  sudo systemctl enable --now docker
  echo "👤 Adding current user to docker group..."
  sudo usermod -aG docker "$USER"
  echo "⚠️  NOTE: You may need to log out and back in (or run 'newgrp docker') for group changes to take effect."
  echo "✅ Docker installed."
else
  echo "✅ Docker is already installed: $(docker --version)"
fi

# ----------------------------
# 2. Install Kind
# Latest stable: v0.31.0 (defaults to Kubernetes 1.35.0)
# Fetches dynamically so future releases are picked up automatically.
# ----------------------------
if ! command -v kind &>/dev/null; then
  echo "📦 Fetching latest Kind version..."
  KIND_VERSION=$(curl -fsSL https://api.github.com/repos/kubernetes-sigs/kind/releases/latest \
    | grep '"tag_name"' \
    | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')

  if [ -z "$KIND_VERSION" ]; then
    echo "❌ Failed to fetch latest Kind version. Check your internet connection."
    exit 1
  fi

  echo "📦 Installing Kind ${KIND_VERSION}..."
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64)           KIND_ARCH="amd64" ;;
    aarch64 | arm64)  KIND_ARCH="arm64" ;;
    *)
      echo "❌ Unsupported architecture: $ARCH"
      exit 1
      ;;
  esac

  curl -fsSLo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${KIND_ARCH}"
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/kind
  echo "✅ Kind ${KIND_VERSION} installed successfully."
else
  echo "✅ Kind is already installed: $(kind version)"
fi

# ----------------------------
# 3. Install kubectl (dynamic latest stable version)
# ----------------------------
if ! command -v kubectl &>/dev/null; then
  echo "📦 Fetching latest stable kubectl version..."
  KUBECTL_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)

  if [ -z "$KUBECTL_VERSION" ]; then
    echo "❌ Failed to fetch latest kubectl version. Check your internet connection."
    exit 1
  fi

  echo "📦 Installing kubectl ${KUBECTL_VERSION}..."
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64)           KUBECTL_ARCH="amd64" ;;
    aarch64 | arm64)  KUBECTL_ARCH="arm64" ;;
    *)
      echo "❌ Unsupported architecture: $ARCH"
      exit 1
      ;;
  esac

  curl -fsSLo ./kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl"

  # Verify checksum before installing
  curl -fsSLo ./kubectl.sha256 "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl.sha256"
  echo "🔐 Verifying kubectl checksum..."
  echo "$(cat ./kubectl.sha256)  ./kubectl" | sha256sum --check --status \
    || { echo "❌ kubectl checksum verification failed! Aborting."; rm -f ./kubectl ./kubectl.sha256; exit 1; }
  rm -f ./kubectl.sha256

  chmod +x ./kubectl
  sudo mv ./kubectl /usr/local/bin/kubectl
  echo "✅ kubectl ${KUBECTL_VERSION} installed successfully."
else
  echo "✅ kubectl is already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

# ----------------------------
# 4. Confirm Versions
# ----------------------------
echo
echo "🔍 Installed Versions:"
echo "  • $(docker --version)"
echo "  • $(kind version)"
echo "  • $(kubectl version --client --short 2>/dev/null || kubectl version --client -o yaml | grep gitVersion | head -1)"
echo
echo "🎉 Docker, Kind, and kubectl installation complete!"
