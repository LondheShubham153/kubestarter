# Online Shop Kubernetes Deployment Guide

This guide provides step-by-step instructions for deploying the Online Shop application on Kubernetes using Kind (Kubernetes in Docker) and Ingress NGINX.

## Prerequisites

- Docker installed
- kubectl installed
- Helm installed
- Kind installed
- An EC2 instance or any cloud VM (optional for production deployment)

## Table of Contents

1. [Setting Up the Kubernetes Cluster](#1-setting-up-the-kubernetes-cluster)
2. [Building and Loading the Docker Image](#2-building-and-loading-the-docker-image)
3. [Deploying the Application](#3-deploying-the-application)
4. [Setting Up Ingress NGINX](#4-setting-up-ingress-nginx)
5. [Accessing the Application](#5-accessing-the-application)
6. [Troubleshooting](#6-troubleshooting)

## 1. Setting Up the Kubernetes Cluster

Create a Kubernetes cluster using Kind with proper port mappings:

```bash
# Create a Kind configuration file
cat <<EOF > kind-cluster.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
    listenAddress: "0.0.0.0"
  - containerPort: 443
    hostPort: 443
    protocol: TCP
    listenAddress: "0.0.0.0"
- role: worker
- role: worker
EOF
```
# Create the Kind cluster
```bash
kind create cluster --name online-shop --config kind-cluster.yaml
```
# Verify the cluster is running
```bash
kubectl cluster-info
```

## 2. Building and Loading the Docker Image
Next, build the Docker image for the application and load it into the Kind cluster:

```bash
# Build the Docker image
docker build -t online_shop:latest .

# Load the image into the Kind cluster
kind load docker-image online_shop:latest --name online-shop
 ```

## 3. Deploying the Application
Create the necessary Kubernetes resources:

```bash
# Create namespace
kubectl apply -f namespace.yml

# Create ConfigMap
kubectl apply -f configmap.yml

# Create Deployment
kubectl apply -f deployment.yml

# Create Service
kubectl apply -f service.yml
 ```

Verify the deployment:

```bash
# Check if pods are running
kubectl get pods -n online-shop-prod

# Check service
kubectl get svc -n online-shop-prod
 ```

## 4. Setting Up Ingress NGINX
Install and configure Ingress NGINX using Helm:

```bash
# Add the Ingress NGINX Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```
```bash
# Create values file for Ingress NGINX
cat <<EOF > ingress-nginx-values.yml
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
spec:
  type: NodePort
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: http
    nodePort: 30080
  - name: https
    port: 443
    protocol: TCP
    targetPort: https
    nodePort: 30443
  selector:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
EOF
```

# Install Ingress NGINX
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind/deploy.yaml

# Wait for Ingress NGINX to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
 ```

Create an Ingress resource:

```bash
# Create Ingress resource
kubectl apply -f ingress.yml
 ```

## 5. Accessing the Application
1. After deployment, verify everything is running:
```bash
# Check all resources
kubectl get pods,svc,ingress -n online-shop-prod
kubectl get pods -n ingress-nginx

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Test local connectivity
curl -v http://localhost

# Test with public IP
curl -v http://13.53.137.11
 ```
