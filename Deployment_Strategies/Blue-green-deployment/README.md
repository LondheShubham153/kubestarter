## Blue-Green Deployment Strategy

- Blue-Green deployment is a strategy used in Kubernetes (and other environments) to reduce downtime and risk when deploying new versions of an application.
- It involves maintaining two separate environments, which are referred to as Blue and Green.


### How it works ?

- <b>Blue Environment:</b> This is the live environment, where the current version of your application is running..
- <b>Green Environment:</b> The new version of the application is deployed to the Green environment. During this phase, there is no impact on the users accessing the Blue environment.
- <b>Test the Green Environment:</b> Once the Green environment is up, it is fully tested to ensure the new version works as expected.
- <b>Switch traffic:</b> After validating that the Green environment is stable, the routing of user traffic is switched from Blue to Green. Now, the Green environment becomes the live production environment, and users interact with the new version.

| Pro's    | Con's |
| -------- | ------- |
| Instant rollout/rollback | Requires double the resources    |
| Avoid versioning issue, change entire cluster state in one go | Proper test of entire platform should be done before releasing to the production environment. |

> [!Note]
>
> This deployment strategy is suitable for Production environment.

![image](https://github.com/user-attachments/assets/ad967289-f554-473b-ba67-4953e57270c2)

---

### Prerequisites to try this:

1. EC2 Instance with Ubuntu OS

2. Docker installed & Configured

3. Kind Installed

4. Kubectl Installed

5. Kind Cluster running(Use `kind-config.yml` file present in this root directory.)

>   [!NOTE]
> 
>   You have to go inside root dir of this repo and create Kind Cluster using command: `kind create cluster --config kind-config.yml --name dep-strg`

---

### Steps to implement Blue Green deployment

- Create a namespace first by using:

    ```bash
    kubectl apply -f blue-green-ns.yml
    ```

- Apply the both deployment manifests (`online-shop-without-footer-blue-deployment.yaml` and `online-shop-green-deployment.yaml`) present in the current directory.

    ```bash
    kubectl apply -f online-shop-without-footer-blue-deployment.yaml
    kubectl apply -f online-shop-green-deployment.yaml
    ```

- Open a new tab of terminal and run the watch command to monitor the deployment

    ```bash
    watch kubectl get pods -n blue-green-ns
    ```

- It will deploy `online shop web page without footer` (Blue environment) and `online shop web page with footer` as a new feature (Green environment), now try to access the blue environment web page on browser.

- Run this command to get all resources created in `blue-green-ns` namespace.

    ```bash
    kubectl get all -n blue-green-ns
    ```

- Forward the `online-shop-blue-deployment-service` svc Port with Nodeport

    ```bash
    kubectl port-forward --address 0.0.0.0 svc/online-shop-blue-deployment-service 30001:3001 -n blue-green-ns &
    ```

- Open the inbound rule for port 30001 in that EC2 Instance and check the application(without footer online shop) at URL:

    ```bash
    http://<Your_Instance_Public_Ip>:30001
    ```

- Without footer online shop app image:

    ![image](https://github.com/user-attachments/assets/d68fda9e-2e18-4086-b64b-a372c3b6dd01)

---

- Forward the `online-shop-green-deployment-service` svc Port with Nodeport

    ```bash
    kubectl port-forward --address 0.0.0.0 svc/online-shop-green-deployment-service 30000:3000 -n blue-green-ns &
    ```

- Open the inbound rule for port 30000 in that EC2 Instance and check the application(With footer online shop) at URL:

    ```bash
    http://<Your_Instance_Public_Ip>:30000
    ```

- With the footer online shop image:
    
    ![image](https://github.com/user-attachments/assets/03409f86-c206-4255-b04b-3d8c9d3741a9)


>   [!Note]
>
>   Check the URL and port carefully 

---

- Now, go to the `online-shop-without-footer-blue-deployment.yaml` manifest file and edit the service's selector field with **`online-shop-green`** selector.

- Previous selector:

    ![image](https://github.com/user-attachments/assets/992edefa-42e8-4a5a-bf9a-8ad15976429d)


- Current selector:

    ![image](https://github.com/user-attachments/assets/39bb2eda-9125-47eb-8293-5e840171a543)


- Apply `online-shop-without-footer-blue-deployment.yaml`

    ```bash
    kubectl apply -f online-shop-without-footer-blue-deployment.yaml
    ```
- Kill all the port-forwarding using the command:
    
    ```bash
    pkill -f "kubectl port-forward"
    ```

- Now again, forward the `online-shop-blue-deployment-service` svc Port with Nodeport

    ```bash
    kubectl port-forward --address 0.0.0.0 svc/online-shop-blue-deployment-service 30001:3001 -n blue-green-ns &
    ```

- Check now, the application has added a new feature as `with footer online shop`, as it previously did not have a footer, but it is now added as a feature, check at URL:

    ```bash
    http://<Your_Instance_Public_Ip>:30001
    ```

- Reload the webpage, you will see `with footer online web page` this time at NodePort: 30001. This means you have successfully switched traffic from a blue environment to a green environment.

    ![image](https://github.com/user-attachments/assets/7c400f73-adbe-4bc6-b54b-a87035611c2c)

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

