## Recreate Deployment Strategy

- Recreate deployment strategy involves the process of terminating all existing running pods before creating new ones.


### How it works ?

- <b>Pod Termination:</b> kubernetes terminates all existing pods.
- <b>Pod Creation:</b> It creates new pods with updated configurations.

| Pro's    | Con's |
| -------- | ------- |
| Application state entirely renewed | Downtime that depends on the both shutdown and boot duration of the application     |

> [!Note]
> This deployment strategy is suitable for development environment.

![image](https://github.com/user-attachments/assets/90197afc-a892-47d5-9160-c4543b64defa)

---

### Prerequisites to try this:

1. EC2 Instance with Ubuntu OS

2. Docker installed & Configured

3. Kind Installed

4. Kubectl Installed

5. Kind Cluster running(Use `kind-config.yml` file present in this directory.)

>   [!NOTE]
> 
>   You have to go inside root dir of this repo and create Kind Cluster using command: `kind create cluster --config kind-config.yml --name dep-strg`

---

### Steps to implement Recreate deployment

- Apply all the manifest files present in the current directory.

    ```bash
    kubectl apply -f .
    ```

- Run this command to get all resources created in `recreate-ns` namespace.

    ```bash
    kubectl get all -n recreate-ns
    ```

- Forward the svc port to the EC2 instance port 3000

    ```bash
    kubectl port-forward --address 0.0.0.0 svc/recreate-service 3000:3000 -n recreate-ns &
    ```

- Open the inbound rule for port 3000 in that EC2 Instance and check the application at URL:

    ```bash
    http://<Your_Instance_Public_Ip>:3000
    ```

- Open a new tab of terminal and connect your EC2 instance and run the watch command to monitor the deployment

    ```bash
    watch kubectl get pods -n recreate-ns
    ```

- You have successfully accessed the `online_shop with footer` webpage. Now edit the deployment file: `recreate-deployment.yml` and change the image from <b>`online_shop`</b> to <b>`online_shop_without_footer`</b> and apply.


    ```bash
    kubectl set image deployment/online-shop online-shop=amitabhdevops/online_shop_without_footer -n recreate-ns
    
    kubectl apply -f . 
    ```

- or, You can only apply deployment file

    ```bash
    kubectl apply -f recreate-deployment.yml
    ```

- Immediately go to second tab where ran watch command and monitor (It will delete all the pods and then create new ones).

---

## Cleanup

- Deleting Kind Cluster:

    ```bash
    kind delete cluster --name dep-strg
    ```

---

> [!Note]
>
> If you cannot access the web app after the update, check your terminal — you probably encountered an error like:
>
>   ```bash
>   error: lost connection to pod
>   ```
>
> Don’t worry! This happens because we’re running the cluster locally (e.g., with **Kind**), and the `kubectl port-forward` session breaks when the underlying pod is replaced during deployment (especially with `Recreate` strategy).
>
> 🔁 Just run the `kubectl port-forward` command again to re-establish the connection and access the app in your browser.
>
> ✅ This issue won't occur when deploying on managed Kubernetes services like **AWS EKS**, **GKE**, or **AKS**, because in those environments you usually expose services using `NodePort`, `LoadBalancer`, or Ingress — not `kubectl port-forward`.
