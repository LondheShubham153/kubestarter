# Apache Helm Chart

### This Helm chart deploys an Apache HTTP Server on a Kubernetes cluster.

### Prerequisites
- Kubernetes cluster running (local, cloud, or KIND).
- kubectl installed and configured.
- Helm 3 installed. Install Helm with:
```bash

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

## Chart Structure
```bash

apache/
├── Chart.yaml         # Chart metadata
├── values.yaml        # Default values for customization
└── templates/         # Kubernetes resource templates
    ├── deployment.yaml
    └── service.yaml
```
- Installation

Clone or navigate to the Helm chart directory.

Package the chart:

```bash

helm package .
```
Install the Helm chart:
```bash

helm install apache ./apache --namespace apache-namespace --create-namespace
```
Default Configuration
The chart deploys an Apache HTTP Server with the following default values (from values.yaml):

```yaml

replicaCount: 2

image:
  repository: httpd
  tag: 2.4
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
  limits:
    memory: "128Mi"
    cpu: "200m"
```
You can customize these values by modifying values.yaml or passing them via the --set flag during installation.

Accessing the Deployment
Check the status of your pods and services:
```bash

kubectl get pods -n apache-namespace
kubectl get svc -n apache-namespace
```
Forward the service port to access Apache locally:
```bash

kubectl port-forward svc/apache 8080:80 -n apache-namespace
```
Open your browser and visit:
```arduino

http://localhost:8080
```
Uninstallation
To remove the deployment and associated resources:

```bash

helm uninstall apache -n apache-namespace
kubectl delete namespace apache-namespace
```
Customizing the Chart
You can override default values using the --set flag. For example:

```bash

helm install apache ./apache \
  --namespace apache-namespace \
  --set replicaCount=3 \
  --set image.tag=2.4.53 \
  --set service.type=LoadBalancer
```
Alternatively, modify the values.yaml file directly.

### Features
- Scalable: Set replicaCount to scale the number of pods.
- Configurable Resources: Customize CPU/memory requests and limits.
- Customizable Service: Supports ClusterIP, NodePort, or LoadBalancer service types.

### Troubleshooting

Verify Helm and Kubernetes versions:
```bash

helm version
kubectl version
```
Check Helm release status:
```bash

helm status apache -n apache-namespace
```
Inspect pod logs:
```bash

kubectl logs <apache-pod-name> -n apache-namespace
```
