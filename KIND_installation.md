
# **Installing KIND Cluster on Ubuntu Using Release Binaries**

This guide provides step-by-step instructions for installing **KIND (Kubernetes IN Docker)** on an Ubuntu machine using release binaries. KIND allows you to run a single-node or multi-node Kubernetes cluster locally for development and testing.

---

## Prerequisites
Before installing KIND Cluster, ensure you have the following:

* Ubuntu OS
* sudo privileges
* Internet access


---


## Step 1: Update System Packages

Update your package lists to make sure you are getting the latest version and dependencies

```bash
sudo apt update
```
![image](https://github.com/user-attachments/assets/67151c22-aa4a-4201-80bf-b4707514047e)


### Step 2: Install Required Packages

Install some basic required packages

```bash
sudo apt install -y curl wget apt-transport-https
```
![image](https://github.com/user-attachments/assets/5e5fa254-69b0-4122-a84e-dfb5b3eb2584)


---


### Step 3: Install Docker

KIND requires Docker to create and manage the Kubernetes clusters.

```bash
sudo apt install -y docker.io
```
![image](https://github.com/user-attachments/assets/c4146d80-e0c5-4259-957f-39f0b6623f95)



Start and enable Docker

```bash
sudo systemctl enable --now docker
sudo systemctl status docker
```
![image](https://github.com/user-attachments/assets/f3babbb9-c599-4199-9ec7-73e52802274c)


Add current user (i.e UBUNTU) to docker group (To use docker without root)

```bash
sudo usermod -aG docker $USER && newgrp docker
```
![image](https://github.com/user-attachments/assets/d024a05a-c5a7-415a-997a-2990d8c08212)

Now, logout (use exit command) and connect again.


---


### Step 4: Install and Create a **KIND** Cluster

1. Download the Latest KIND Binary:

   ```bash
   [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.25.0/kind-linux-amd64
   ```

2. Make the Binary Executable:

   Change the downloaded binary's permissions to make it executable:

   ```bash
   chmod +x ./kind
   ```

3. Move the Binary to a Directory in Your PATH:

   Move the Kind binary to `/usr/local/bin` to make it globally accessible.

   ```bash
   sudo mv ./kind /usr/local/bin/kind
   ```
   ![image](https://github.com/user-attachments/assets/14728c13-0217-4c89-a403-3b3216cb3751)



4. Verify Installation:

   Check that the installation was successful by verifying the `KIND` version:

   ```bash
   kind --version
   ```
   ![image](https://github.com/user-attachments/assets/2da1b0f9-63bc-4379-a184-cc5c992b0e66)


5. Create a KIND Cluster and verify status

   ```bash
   kind create cluster --name my-cluster
   kubectl cluster-info --context kind-mycluster
   kind get clusters
   ```
   ![image](https://github.com/user-attachments/assets/05fb8365-6b95-4e14-b7cb-94802ade0031)


---


## Step 5: Download and Install Kubectl

Once the cluster is created, you can interact with it using `kubectl`.

1. Download the Kubectl binary and verify the downloaded binary is correct

```bash
curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum –check
```
![image](https://github.com/user-attachments/assets/81856385-f5eb-4b91-b687-4586908477e5)

2. Install the Kubelet

```bash
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
kubectl version --client --output=yaml
```
![image](https://github.com/user-attachments/assets/8d67f7e3-ffca-4771-bfae-1af08a30ef31)

3. Verify the Install

```bash
kubectl version
```
![image](https://github.com/user-attachments/assets/24bcb960-7c20-4b84-812f-ac97a0ee2fcb)

4. Check Nodes status in KIND Cluster which is created (Here we have created only 1 node cluster)

```bash
kubectl get nodes
```
![image](https://github.com/user-attachments/assets/f526c023-e1b6-40a4-97e1-8178c2b8ac17)


---


## Step 6: Optional: Delete KIND Cluster

If you wish to delete the cluster after you're done:

```bash
kind delete cluster --name my-cluster
```
![image](https://github.com/user-attachments/assets/9685d3a9-a751-4d27-8a16-b46d52f0266a)


---



You have successfully installed Kind and created a Kubernetes cluster using the release binaries. You can now use Kind to test and develop Kubernetes workloads in an isolated environment on your local machine.
