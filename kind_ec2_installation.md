# Kind K8s Installation Guide for AWS EC2 
<img src="https://github.com/user-attachments/assets/2942ee8e-7e11-4f58-a1de-bc939a33b8ab" alt="kind logo" style="height: 50px; width: auto;">
<img src="https://github.com/user-attachments/assets/2af10983-a2f4-492a-961c-28b6f36f977a" alt="k8s logo" style="height: 50px; width: auto;">
<img src="https://github.com/user-attachments/assets/9f1b82ea-d285-43ed-b7de-564019075ab1" alt="docker logo" style="height: 50px; width: auto;">
<img src="https://github.com/user-attachments/assets/51fea0a8-3a8c-4727-8129-784c35f1389c" alt="ec2 logo" style="height: 50px; width: auto;">  

This guide provides step-by-step instructions for installing Kind K8s on AWS EC2 (Ubuntu). Kind allows you to run a single-node Kubernetes cluster locally for development and testing purposes.

> ⚠️ **Caution:**  
> This installation guide recommends using a `t2.medium` EC2 instance, which is **NOT** covered under the AWS Free Tier.  
> Please be aware that using this instance type may incur **ADDITIONAL CHARGES**. For optimal performance with Kind K8s, it is advised to use a higher-tier EC2 instance to meet the computational requirements and **not** `t2.micro`.


## Pre-requisites
* AWS EC2 (Ubuntu)
* Docker
* kubectl

## Pre-requisites Installation
### 1. Create an EC2 (Ubuntu) and connect to it
* Create an EC2 of Instance type `t2.medium` and storage size of `15 GB` or more
* Launch the newly created EC2 and connect to it 

### 2. Update system packages
Update your package lists to make sure you are getting the latest version and dependencies.

```bash
sudo apt update
```

![update-sys-package](https://github.com/user-attachments/assets/64a4d6f2-8039-4bf8-ab6d-eeab1c8b8e5b)

### 3. Install Docker

Since **kind** runs Kubernetes clusters using Docker containers as nodes, Docker needs to be installed.

* Install Docker using the below command
  ```bash
  sudo apt install docker.io -y
  ```

![install-docker](https://github.com/user-attachments/assets/8abdd518-ba2a-479d-b898-3c2eacd256e6)

Docker service will be started and enabled by default. Verify if its started and enabled using `sudo systemctl status docker`   

![systemctl-status-docker](https://github.com/user-attachments/assets/31526fcb-cbe2-4f95-9b3b-e520f9e12d81)

* If Docker service is not started or enabled, do it using the command below
  ```bash
  sudo systemctl enable --now docker
  ```

* Add current user to docker group (To use docker without root)

  ```bash
  sudo usermod -aG docker $USER && newgrp docker
  ```
* Verify using `docker --version`
  
  ![docker-version](https://github.com/user-attachments/assets/f9fe3f02-4178-4102-a088-0edec30494ac)


### 4. Install kubectl

Download **kubectl**, which is a Kubernetes command-line tool.

* Download kubectl binary with curl on Linux
  ```bash
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  ```

> **Optional**: **Validate the downloaded kubectl binary  **
> * Download the kubectl checksum file  
> `curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"`  
> * Validate the kubectl binary against the checksum file  
> `echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check`  
> * If valid, the output is `kubectl: OK`

* Install kubectl
  ```bash
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  ```

* Verify installation by checking kubectl version
  ```bash
  kubectl version --client
  ```
  
![kubectl-all](https://github.com/user-attachments/assets/a5808228-1ac0-4f6d-b3a1-b68417556c91)

## Kind K8s Installation
### Install Kind
Download and install **kind** k8s
* Download kind binary with curl on Linux
  ```bash
  [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.25.0/kind-linux-amd64
  ```
* Install kind
  ```bash
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/kind
  ```
* Run `kind` to verify if its installed
 
![kind-all](https://github.com/user-attachments/assets/83f53246-a60e-49dc-a4a7-e8418354e9bb)

## Kind K8s Usage
### Create a Cluster
Create a Kubernetes Cluster using `kind create cluster`. Use the `--name` flag to provide a cluster name. For Example, `kind create cluster --name=<cluster-name>` (Replace `<cluster-name>` with desired cluster name). 

![kind-create-cluster](https://github.com/user-attachments/assets/173f4a67-000c-497c-a878-0b2da85e2736)

### Interacting with Clusters
`kubectl` can be used to interact with created clusters. 

* To list all the clusters, execute `kind get clusters`
  
![kind-get-clusters](https://github.com/user-attachments/assets/0514244b-0517-402a-86e1-0712c08c8bae)

* To get nodes, run `kubectl get nodes`
  
![kind node](https://github.com/user-attachments/assets/9a035322-a85f-4a98-8716-6dff777a20a5)

### Optional: Delete cluster
Delete a Kubernetes Cluster using `kind delete cluster`. Use the `--name` flag to provide a cluster name. For Example, `kind delete cluster --name=<cluster-name>` (Replace `<cluster-name>` with desired cluster name).  

![kind delete cluster](https://github.com/user-attachments/assets/766629d4-6b99-4ab9-a33f-f3e63e0e7916)


