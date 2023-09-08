# Kubeadm Installation Guide

This guide outlines the steps needed to set up a Kubernetes cluster using kubeadm.

## Pre-requisites

* Ubuntu OS (Xenial or later)
* sudo privileges
* Internet access
* t2.medium instance type or higher

---

## Both Master & Worker Node

Run the following commands on both the master and worker nodes to prepare them for kubeadm.

```bash
# using 'sudo su' is not a good practice.
sudo apt update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo apt install docker.io -y

sudo systemctl enable --now docker # enable and start in single command.

# Adding GPG keys.
curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg

# Add the repository to the sourcelist.
echo 'deb https://packages.cloud.google.com/apt kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update 
sudo apt install kubeadm=1.20.0-00 kubectl=1.20.0-00 kubelet=1.20.0-00 -y
```

**Sample Command run on master node**

<kbd>![image](https://github.com/paragpallavsingh/kubernetes-kickstarter/assets/40052830/a4e7a4af-31fa-40cf-bb9e-64ba18999cb5)</kbd>

<kbd>![image](https://github.com/paragpallavsingh/kubernetes-kickstarter/assets/40052830/acf157b8-5c7b-44e7-91ef-b5437053be60)</kbd>

<kbd>![image](https://github.com/paragpallavsingh/kubernetes-kickstarter/assets/40052830/8f960aae-3706-43cd-bac8-1903fbe8196d)</kbd>

---

## Master Node

1. Initialize the Kubernetes master node.

    ```bash
    sudo kubeadm init
    ```
    <kbd>![image](https://github.com/paragpallavsingh/kubernetes-kickstarter/assets/40052830/4fed3d68-eb41-423d-b83f-35c3cc11476e)</kbd>

    After succesfully running, your Kubernetes control plane will be initialized successfully.

   <kbd>![image](https://github.com/paragpallavsingh/kubernetes-kickstarter/assets/40052830/760276f4-9146-4bc1-aa92-48cc1c0b13f4)</kbd>


3. Set up local kubeconfig (both for root user and normal user):

    ```bash
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```

    <kbd>![image](https://github.com/paragpallavsingh/kubernetes-kickstarter/assets/40052830/f647adc1-0976-490e-b9c9-f6f96908d6fe)</kbd>


4. Apply Weave network:

    ```bash
    kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
    ```

    <kbd>![image](https://github.com/paragpallavsingh/kubernetes-kickstarter/assets/40052830/ec7b4684-7719-4d09-81d8-eee27b98972a)</kbd>


5. Generate a token for worker nodes to join:

    ```bash
    sudo kubeadm token create --print-join-command
    ```

    <kbd>![image](https://github.com/paragpallavsingh/kubernetes-kickstarter/assets/40052830/0370839b-bbac-415c-9d5a-9ab52cd3108b)</kbd>

6. Expose port 6443 in the Security group for the Worker to connect to Master Node

<kbd>![image](https://github.com/paragpallavsingh/kubernetes-kickstarter/assets/40052830/b3f5df01-acb0-419f-aa70-6d51819f4ec0)</kbd>


---

## Worker Node

1. Run the following commands on the worker node.

    ```bash
    sudo kubeadm reset pre-flight checks
    ```
    <kbd>![image](https://github.com/paragpallavsingh/kubernetes-kickstarter/assets/40052830/3d29912b-f1a3-4e0b-a6ee-6c9cc5db49fb)</kbd>

2. Paste the join command you got from the master node and append `--v=5` at the end.
*Make sure either you are working as sudo user or use `sudo` before the command*

   <kbd>![image](https://github.com/paragpallavsingh/kubernetes-kickstarter/assets/40052830/c41e3213-7474-43f9-9a7b-a75694be582a)</kbd>

   After succesful join->
   <kbd>![image](https://github.com/paragpallavsingh/kubernetes-kickstarter/assets/40052830/c530b65a-4afd-4b1d-9748-421c216d64cd)</kbd>

---

## Verify Cluster Connection

On Master Node:

```bash
kubectl get nodes
```
<kbd>![image](https://github.com/paragpallavsingh/kubernetes-kickstarter/assets/40052830/4ed4dcac-502a-4cc1-a63e-c9cbb0199428)</kbd>

---

## Optional: Labeling Nodes

If you want to label worker nodes, you can use the following command:

```bash
kubectl label node <node-name> node-role.kubernetes.io/worker=worker
```

---

## Optional: Test a demo Pod 

If you want to test a demo pod, you can use the following command:

```bash
kubectl run hello-world-pod --image=busybox --restart=Never --command -- sh -c "echo 'Hello, World' && sleep 3600"
```

<kbd>![image](https://github.com/paragpallavsingh/kubernetes-kickstarter/assets/40052830/bace1884-bbba-4e2f-8fb2-83bbba819d08)</kbd>
