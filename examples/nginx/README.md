### Interview Questions:

1. **Explain the role of a Kubernetes Pod when deploying an Nginx web server.**

   Answer: A Kubernetes Pod is the smallest deployable unit and represents a single instance of a running process. When deploying Nginx, a Pod encapsulates the Nginx container along with shared networking and storage resources.

2. **What is the purpose of using a Kubernetes Service when deploying Nginx?**

   Answer: A Kubernetes Service provides a stable network endpoint for accessing Nginx Pods. It enables load balancing, service discovery, and ensures availability even if Pods are rescheduled or scaled.

3. **How does a Kubernetes Deployment enhance the deployment of an Nginx application?**

   Answer: A Kubernetes Deployment manages the lifecycle of Nginx Pods. It enables declarative updates, scaling, and self-healing by maintaining a desired number of replica Pods based on a defined configuration.

4. **Why would you use a Namespace when deploying Nginx and related resources?**

   Answer: A Namespace provides a virtual cluster environment within a physical cluster. It helps in organizing and isolating resources, making it easier to manage and monitor Nginx-related components separately.

### Manifest File Examples:

1. **Nginx Pod Manifest in "nginx" Namespace:**

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: nginx-pod
     namespace: nginx
   spec:
     containers:
       - name: nginx-container
         image: nginx:latest
   ```

2. **Nginx Service Manifest in "nginx" Namespace:**

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: nginx-service
     namespace: nginx
   spec:
     selector:
       app: nginx-app
     ports:
       - protocol: TCP
         port: 80
         targetPort: 80
   ```

3. **Nginx Deployment Manifest in "nginx" Namespace:**

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nginx-deployment
     namespace: nginx
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: nginx-app
     template:
       metadata:
         labels:
           app: nginx-app
       spec:
         containers:
           - name: nginx-container
             image: nginx:latest
   ```

### Nginx Namespace Deployment Steps:

1. **Create the "nginx" Namespace:**

   ```sh
   kubectl create namespace nginx
   ```

2. **Apply the Nginx Pod, Service, and Deployment YAMLs within the "nginx" Namespace:**

   ```sh
   kubectl apply -f nginx-pod.yaml -n nginx
   kubectl apply -f nginx-service.yaml -n nginx
   kubectl apply -f nginx-deployment.yaml -n nginx
   ```

