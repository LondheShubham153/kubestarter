# Installing Cluster Components with Helm and Kustomize
```
# Add community repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack (Prometheus + Alertmanager + Grafana)
helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace

# Check components
kubectl get pods -n monitoring
helm status monitoring -n monitoring
```
