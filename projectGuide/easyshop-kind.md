# Kind Cluster Setup Guide for EasyShop

This guide will help you set up a Kind (Kubernetes in Docker) cluster for the EasyShop application. Instructions are provided for Windows, Linux, and macOS.

## 📋 Prerequisites Installation

> ### Windows
> 1. Install Docker Desktop for Windows
>    ```powershell
>    winget install Docker.DockerDesktop
>    ```
> 2. Install Kind
>    ```powershell
>    curl.exe -Lo kind-windows-amd64.exe https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64
>    Move-Item .\kind-windows-amd64.exe c:\windows\system32\kind.exe
>    ```
> 3. Install kubectl
>    ```powershell
>    curl.exe -LO "https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe"
>    Move-Item .\kubectl.exe c:\windows\system32\kubectl.exe
>    ```

> ### Linux
> 1. Install Docker
>    ```bash
>    curl -fsSL https://get.docker.com -o get-docker.sh
>    sudo sh get-docker.sh
>    rm get-docker.sh
>    ```
> 2. Install Kind
>    ```bash
>    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
>    chmod +x ./kind
>    sudo mv ./kind /usr/local/bin/kind
>    ```
> 3. Install kubectl
>    ```bash
>    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
>    chmod +x kubectl
>    sudo mv ./kubectl /usr/local/bin/kubectl
>    ```

> ### macOS
> 1. Install Docker Desktop for Mac
>    ```bash
>    brew install --cask docker
>    ```
> 2. Install Kind
>    ```bash
>    brew install kind
>    ```
> 3. Install kubectl
>    ```bash
>    brew install kubectl
>    ```

## 🛠️ Environment Setup

> ### 1. Clone the repository and navigate to the project directory   
>   ```bash
>   git clone https://github.com/your-username/EasyShop.git
>   cd EasyShop
>   ```

> ### 2. Create ConfigMap
> Create `kubernetes/configmap.yaml` with the following content:
>   ```yaml
>   apiVersion: v1
>   kind: ConfigMap
>   metadata:
>     name: easyshop-config
>     namespace: easyshop
>   data:
>     MONGODB_URI: "mongodb://mongodb-service:27017/easyshop"
>     NODE_ENV: "production"
>     NEXT_PUBLIC_API_URL: "http://YOUR_EC2_PUBLIC_IP/api"  # Replace YOUR_EC2_PUBLIC_IP
>     NEXTAUTH_URL: "http://YOUR_EC2_PUBLIC_IP"             # Replace YOUR_EC2_PUBLIC_IP
>     NEXTAUTH_SECRET: "HmaFjYZ2jbUK7Ef+wZrBiJei4ZNGBAJ5IdiOGAyQegw="
>     JWT_SECRET: "e5e425764a34a2117ec2028bd53d6f1388e7b90aeae9fa7735f2469ea3a6cc8c"
>   ```

> ### 3. Build and Push Docker Images
> 
> #### 3.1 Login to Docker Hub
> First, login to Docker Hub (create an account at [hub.docker.com](https://hub.docker.com) if you haven't):
> ```bash
> docker login
> ```
>
> #### 3.2 Build Application Image
> ```bash
> # Build the application image
> docker build -t your-dockerhub-username/easyshop:latest .
> 
> # Push to Docker Hub
> docker push your-dockerhub-username/easyshop:latest
> ```
>
> #### 3.3 Build Migration Image
> ```bash
> # Build the migration image
> docker build -t your-dockerhub-username/easyshop-migration:latest -f Dockerfile.migration .
> 
> # Push to Docker Hub
> docker push your-dockerhub-username/easyshop-migration:latest
> ```


## Kind Cluster Setup

1. Create new cluster
   
   ```bash
   kind create cluster --name easyshop --config kubernetes/kind-config.yaml
    ```

   
   This command creates a new Kind cluster using our custom configuration with one control plane and two worker nodes.
3. Install NGINX Ingress Controller
   
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    ```
   
   Wait for the ingress controller to be ready:
   
   ```bash
   kubectl wait --namespace ingress-nginx \
     --for=condition=ready pod \
     --selector=app.kubernetes.io/component=controller \
     --timeout=90s
    ```
4. Apply Kubernetes manifests
   
   ```bash
   # Create namespace
   kubectl apply -f kubernetes/namespace.yaml
   
   # Setup storage
   kubectl apply -f kubernetes/storage-class.yaml
   kubectl apply -f kubernetes/mongodb-pv.yaml
   kubectl apply -f kubernetes/mongodb-pvc.yaml
   
   # Deploy MongoDB
   kubectl apply -f kubernetes/mongodb-service.yaml
   kubectl apply -f kubernetes/mongodb-statefulset.yaml
   
   # Wait for MongoDB to be ready
   kubectl wait --namespace easyshop \
     --for=condition=ready pod \
     --selector=app=mongodb \
     --timeout=90s
    ```
5. Load required images
   
   ```bash
   # Pull images
   docker pull iemafzal/easyshop:latest
   docker pull iemafzal/easyshop-migration:latest
    ```
6. Deploy application
   
   ```bash
   # Apply ConfigMap
   kubectl apply -f kubernetes/configmap.yaml
   
   # Run database migration
   kubectl apply -f kubernetes/migration-job.yaml
   
   # Deploy application
   kubectl apply -f kubernetes/app-service.yaml
```

## 🚀 Application Deployment

### 1. Update Deployment Manifest
Create or update `kubernetes/app-deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: easyshop
  namespace: easyshop
spec:
  replicas: 2
  selector:
    matchLabels:
      app: easyshop
  template:
    metadata:
      labels:
        app: easyshop
    spec:
      containers:
        - name: easyshop
          image: iemafzal/easyshop:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 3000
          envFrom:
            - configMapRef:
                name: easyshop-config
            - secretRef:
                name: easyshop-secrets
          env:
            - name: NEXTAUTH_URL
              valueFrom:
                configMapKeyRef:
                  name: easyshop-config
                  key: NEXTAUTH_URL
            - name: NEXTAUTH_SECRET
              valueFrom:
                secretKeyRef:
                  name: easyshop-secrets
                  key: NEXTAUTH_SECRET
            - name: JWT_SECRET
              valueFrom:
                secretKeyRef:
                  name: easyshop-secrets
                  key: JWT_SECRET
          resources:
            requests:
              memory: "256Mi"
              cpu: "200m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          startupProbe:
            httpGet:
              path: /
              port: 3000
            failureThreshold: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 20
            periodSeconds: 15
          livenessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 25
            periodSeconds: 20
```

> ### 2. Update Migration Job
> Create or update `kubernetes/migration-job.yaml`:
> ```yaml
> apiVersion: batch/v1
> kind: Job
> metadata:
>   name: db-migration
>   namespace: easyshop
> spec:
>   template:
>     spec:
>       containers:
>       - name: migration
>         image: iemafzal/easyshop-migration:latest
>         imagePullPolicy: Always
>         env:
>         - name: MONGODB_URI
>           value: "mongodb://mongodb-service:27017/easyshop"
>       restartPolicy: OnFailure
> ```

> ### 3. Update Ingress Configuration
> Create or update `kubernetes/ingress.yaml`:
> ```yaml
> apiVersion: networking.k8s.io/v1
> kind: Ingress
> metadata:
>   name: easyshop-ingress
>   namespace: easyshop
>   annotations:
>     nginx.ingress.kubernetes.io/ssl-redirect: "false"
>     nginx.ingress.kubernetes.io/proxy-body-size: "50m"
> spec:
>   rules:
>   - host: "51.20.251.235.nip.io"
>     http:
>       paths:
>       - path: /
>         pathType: Prefix
>         backend:
>           service:
>             name: easyshop-service
>             port:
>               number: 80
> ```

> ### 4. Apply the Configurations
> ```bash
> # Apply all configurations
> kubectl apply -f kubernetes/app-deployment.yaml
> kubectl apply -f kubernetes/migration-job.yaml
> kubectl apply -f kubernetes/ingress.yaml
> 
> # Verify the deployment
> kubectl get pods -n easyshop
> kubectl get ingress -n easyshop
> ```

```bash   
   # Apply ConfigMap
   kubectl apply -f kubernetes/configmap.yaml
```
```bash
   # Run database migration
   kubectl apply -f kubernetes/migration-job.yaml
```
```bash
   # Deploy application
   kubectl apply -f kubernetes/app-service.yaml
   kubectl apply -f kubernetes/app-deployment.yaml
   kubectl apply -f kubernetes/ingress.yaml
```
7. Configure local DNS (requires admin/root privileges)
   
   ```bash
   echo "127.0.0.1 easyshop.local" | sudo tee -a /etc/hosts
   ```

## Verification
1. Check deployment status
   
   ```bash
   kubectl get pods -n easyshop
    ```
2. Check services
   
   ```bash
   kubectl get svc -n easyshop
    ```
3. Verify ingress
   
   ```bash
   kubectl get ingress -n easyshop
    ```
4. Test MongoDB connection
   
   ```bash
   kubectl exec -it -n easyshop mongodb-0 -- mongosh --eval "db.serverStatus()"
    ```
## Accessing the Application
The application should now be accessible at:

- http://localhost
- http://easyshop.local
## Troubleshooting
1. If pods are not starting, check logs:
   
   ```bash
   kubectl logs -n easyshop <pod-name>
    ```
2. For MongoDB connection issues:
   
   ```bash
   kubectl exec -it -n easyshop mongodb-0 -- mongosh
    ```
3. To restart deployments:
   
   ```bash
   kubectl rollout restart deployment/easyshop -n easyshop
    ```
## Cleanup
To delete the cluster:

```bash
kind delete cluster --name easyshop
 ```
