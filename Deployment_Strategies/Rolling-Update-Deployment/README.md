## Rolling Update Deployment Strategy

- A rolling update in Kubernetes is a deployment strategy used to gradually replace the existing set of Pods with a new set of Pods one by one.
- This ensures that there is no downtime during the update process as the application continues to serve requests while the update is in progress.


### How it works ?

- <b>Pod Creation:</b> kubernetes creates one new pod of newer version.
- <b>Pod Termination:</b> It terminates existing pods.

| Pro's    | Con's |
| -------- | ------- |
| Version is slowly released across instances | Rollout/Rollback can take time    |
| Convenient for stateful applications | No control over traffic |

> [!Note]
> This deployment strategy is suitable for UAT,QA environment.
> For stateful applications suitable on production environment

![image](https://github.com/user-attachments/assets/ef9a9088-0f0b-4645-9c66-505481c7eb6f)

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

### Steps to implement rolling-update deployment

- Apply all the manifest files present in the current directory.

    ```bash
    kubectl apply -f .
    ```

- Run this command to get all resources created in `rolling-ns` namespace.

    ```bash
    kubectl get all -n rolling-ns
    ```

- Forward the svc port to the EC2 instance port 3000

    ```bash
    kubectl port-forward --address 0.0.0.0 svc/rolling-update-service 3000:3000 -n rolling-ns &
    ```

- Open the inbound rule for port 3000 in that EC2 Instance and check the application at URL:

    ```bash
    http://<Your_Instance_Public_Ip>:3000
    ```

- Open a new tab of terminal and connect your EC2 instance and run the watch command to monitor the deployment

    ```bash
    watch kubectl get pods -n rolling-ns
    ```

- You have successfully accessed the `online_shop with footer` webpage. Now edit the deployment file and change the image from <b>`online_shop`</b> to <b>`online_shop_without_footer`</b> and apply.

    ```bash
    kubectl apply -f . 
    ```

- or, You can only apply deployment file

    ```bash
    kubectl apply -f rolling-deployment.yml
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

