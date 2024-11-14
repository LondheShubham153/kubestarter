
# Minikube Installation on Windows/local System.

This guide provides step-by-step instructions for installing Minikube on windows with pre-requisites. Minikube allows you to run a single-node Kubernetes cluster locally for development and testing purposes.


## Pre-requisites

- Windows os
- Internet connection
- Container manager : Docker
- kubernetes cmd : kubectl


## Step 1: Docker Installation
visit the below link 
to download and install the docker desktop.

```bash
  https://docs.docker.com/desktop/install/windows-install/
```
 ## It will require a RESTART.
Now open cmd and check installation.

```bash
  docker --version


  output:
  Docker version 27.0.3, build 7d4bcd8
```
successfully installed docker on windows.

## Step 2: Minikube Installation

Now open poweshell and run below 2 commands.
```bash
New-Item -Path 'c:\' -Name 'minikube' -ItemType Directory -Force
Invoke-WebRequest -OutFile 'c:\minikube\minikube.exe' -Uri 'https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe' -UseBasicParsing

```
```bash
$oldPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine)
if ($oldPath.Split(';') -inotcontains 'C:\minikube'){
  [Environment]::SetEnvironmentVariable('Path', $('{0};C:\minikube' -f $oldPath), [EnvironmentVariableTarget]::Machine)
}
```
check the installation by 
```bash
minikube version


output:
minikube version: v1.33.1
commit: 5883c09216182566a63dff4c326a6fc9ed2982ff
```

## Step 3: Run Minikube 
- Open powershell run below cmd to create brand new cluster.
```bash
minikube start
```
## Step 4: Install kubectl With Curl
- Open powershell run below command to interact with your brand new cluster.
- Install curl if not availabe bydefault it is present.
```bash
curl.exe -LO "https://dl.k8s.io/release/v1.30.0/bin/windows/amd64/kubectl.exe"
```
## Step 5: Play With Your Cluster.

```bash
kubectl get nodes


output: 
NAME       STATUS   ROLES           AGE     VERSION
minikube   Ready    control-plane   3m54s   v1.30.0
```
This shows your single node cluster in up and running.

## Step 6: Don't Forget to Stop & Delete Minikube.
When you are done, you can stop the Minikube cluster with:
```bash
minikube stop
```
If you wish to delete the Minikube cluster entirely, you can do so with:
```bash
minikube delete
```

That's it! You've successfully installed Minikube on Windows, and you can now start deploying Kubernetes applications for development and testing.

    
