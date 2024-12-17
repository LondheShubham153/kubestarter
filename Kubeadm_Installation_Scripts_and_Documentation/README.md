# Kubeadm Installation Guide

This guide outlines the steps needed to set up a Kubernetes cluster using `kubeadm`.

## Prerequisites

- Ubuntu OS (Xenial or later)
- `sudo` privileges
- Internet access
- t2.medium instance type or higher

---

## AWS Setup

1. Ensure that all instances are in the same **Security Group**.
2. Expose port **6443** in the **Security Group** to allow worker nodes to join the cluster.
3. Expose port **22** in the **Security Group** to allows SSH access to manage the instance..


## To do above setup, follow below provided steps : 

    ### **Step 1: Identify or Create a Security Group**
    1. **Log in to the AWS Management Console**:
       - Go to the **EC2 Dashboard**.

    2. **Locate Security Groups**:
       - In the left menu under **Network & Security**, click on **Security Groups**.

    3. **Create a New Security Group**:
       - Click on **Create Security Group**.
       - Provide the following details:
         - **Name**: (e.g., `Kubernetes-Cluster-SG`)
         - **Description**: A brief description for the security group(for creating sg it is mendatory).
         - **VPC**: Select the appropriate VPC for your instances(you can select default as well).

    4. **Add Rules to the Security Group**:
       - **Allow SSH Traffic (Port 22) (for managing the instances)**:
         - **Type**: SSH
         - **Port Range**: `22`
         - **Source**: `0.0.0.0/0` (Anywhere) or restrict it to your IP for better security.
         
       - **Allow Kubernetes API Traffic (Port 6443)**:
         - **Type**: Custom TCP
         - **Port Range**: `6443`
         - **Source**: `0.0.0.0/0` (Anywhere) or restrict it to specific IP ranges.

    5. **Save the Rules**:
       - Click on **Create Security Group** to save the settings.

    ---

    ### **Step 2: Select the Security Group While Creating Instances**
    - When launching EC2 instances:
      - Under **Configure Security Group**, select the existing security group you created (`Kubernetes-Cluster-SG`).


> If you want to update security group in future you can update it easily,just google it.

---


## Execute on Both "Master" & "Worker" Nodes

1. **Disable Swap**: Required for Kubernetes to function correctly.
    ```bash
    sudo swapoff -a
    ```

2. **Load Necessary Kernel Modules**: Required for Kubernetes networking.
    ```bash
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
    overlay
    br_netfilter
    EOF

    sudo modprobe overlay
    sudo modprobe br_netfilter
    ```

3. **Set Sysctl Parameters**: Helps with networking.
    ```bash
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-iptables  = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.ipv4.ip_forward                 = 1
    EOF

    sudo sysctl --system
    lsmod | grep br_netfilter
    lsmod | grep overlay
    ```

4. **Install Containerd**:
    ```bash
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y containerd.io

    containerd config default | sed -e 's/SystemdCgroup = false/SystemdCgroup = true/' -e 's/sandbox_image = "registry.k8s.io\/pause:3.6"/sandbox_image = "registry.k8s.io\/pause:3.9"/' | sudo tee /etc/containerd/config.toml

    sudo systemctl restart containerd
    sudo systemctl status containerd
    ```

5. **Install Kubernetes Components**:
    ```bash
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gpg

    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
    ```

## Execute ONLY on the "Master" Node

1. **Initialize the Cluster**:
    ```bash
    sudo kubeadm init
    ```

2. **Set Up Local kubeconfig**:
    ```bash
    mkdir -p "$HOME"/.kube
    sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
    sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config
    ```

3. **Install a Network Plugin (Calico)**:
    ```bash
    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml
    ```

4. **Generate Join Command**:
    ```bash
    kubeadm token create --print-join-command
    ```

> Copy this generated token for next command.

---

## Execute on ALL of your Worker Nodes

1. Perform pre-flight checks:
    ```bash
    sudo kubeadm reset pre-flight checks
    ```

2. Paste the join command you got from the master node and append `--v=5` at the end:
    ```bash
    sudo kubeadm join <private-ip-of-control-plane>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash> --cri-socket 
    "unix:///run/containerd/containerd.sock" --v=5
    ```

    > **Note**: When pasting the join command from the master node:
    > 1. Add `sudo` at the beginning of the command
    > 2. Add `--v=5` at the end
    >
    > Example format:
    > ```bash
    > sudo <paste-join-command-here> --v=5
    > ```

---

## Verify Cluster Connection

**On Master Node:**

```bash
kubectl get nodes

```

   <img src="https://raw.githubusercontent.com/faizan35/kubernetes_cluster_with_kubeadm/main/Img/nodes-connected.png" width="70%">

---

## Verify Container Status on Worker Node
<img src="https://github-production-user-asset-6210df.s3.amazonaws.com/106548243/356852724-c3d3732f-5c99-4a27-a574-86bc7ae5a933.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAVCODYLSA53PQK4ZA%2F20241217%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20241217T113912Z&X-Amz-Expires=300&X-Amz-Signature=7a5a38a006bb504d47ccd2c35a0f6799c03ea7974e9794661a744f866bf3a6ca&X-Amz-SignedHeaders=host" width="70%">


