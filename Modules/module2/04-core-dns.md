# CoreDNS Configuration and Troubleshooting

## Overview

CoreDNS is the default DNS server in Kubernetes clusters (since v1.13). It provides service discovery by resolving service names to cluster IPs, enabling pods to communicate using DNS names instead of IP addresses.

## Why CoreDNS Matters

- **Service Discovery**: Pods find services by name (e.g., `backend-service`)
- **Cross-Namespace Communication**: Access services in other namespaces
- **External DNS Resolution**: Resolves external domain names
- **Custom DNS Configuration**: Add custom DNS entries and forwarding rules

## How Kubernetes DNS Works

### DNS Naming Convention

```
<service-name>.<namespace>.svc.cluster.local
```

**Examples**:
```bash
# Same namespace
curl http://backend-service

# Different namespace
curl http://backend-service.production

# Fully qualified domain name (FQDN)
curl http://backend-service.production.svc.cluster.local

# External domain
curl http://google.com
```

### DNS Resolution Flow

1. Pod makes DNS query (e.g., `backend-service`)
2. Query sent to CoreDNS (usually at `10.96.0.10`)
3. CoreDNS checks:
   - Is it a Kubernetes service? → Return ClusterIP
   - Is it external? → Forward to upstream DNS
4. Response returned to pod

---

## Common DNS Patterns

### Pattern 1: Custom DNS Entries

**Use case**: Add custom DNS records for external services

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
        }
        # Custom hosts
        hosts {
           192.168.1.100 custom-db.example.com
           fallthrough
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
```
**Apply changes**:
```bash
kubectl edit configmap coredns -n kube-system
# CoreDNS will auto-reload
```
---

### Pattern 2: Increase Cache TTL

**Use case**: Reduce DNS query load for stable services

```yaml
data:
  Corefile: |
    .:53 {
        errors
        health
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 300  # Increase from 30 to 300 seconds
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 300  # Increase cache duration
        loop
        reload
        loadbalance
    }
```

---

## Troubleshooting Guide

### Example 1: DNS Resolution Fails (nslookup fails)

**ERRor**:
```bash
kubectl exec -it test-pod -- nslookup kubernetes.default
# Server:    10.96.0.10
# Address 1: 10.96.0.10
# nslookup: can't resolve 'kubernetes.default'
```

**Debug Steps**:
```bash
# 1. Check if CoreDNS pods are running
kubectl get pods -n kube-system -l k8s-app=kube-dns

# 2. Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# 3. Check CoreDNS service
kubectl get svc -n kube-system kube-dns

# 4. Verify DNS service IP
kubectl get svc -n kube-system kube-dns -o jsonpath='{.spec.clusterIP}'

# 5. Check pod's DNS configuration
kubectl exec -it test-pod -- cat /etc/resolv.conf

# 6. Test DNS from node
nslookup kubernetes.default.svc.cluster.local 10.96.0.10
```

**Solutions**:

**A. CoreDNS pods not running**:
```bash
# Check pod status
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Describe pod for errors
kubectl describe pod -n kube-system <coredns-pod>

# Restart CoreDNS
kubectl rollout restart deployment coredns -n kube-system
```
**B. Wrong DNS service IP in pod**:
```bash
# Check kubelet DNS configuration
# On node:
cat /var/lib/kubelet/config.yaml | grep -A 2 clusterDNS

# Should match kube-dns service IP
kubectl get svc -n kube-system kube-dns -o jsonpath='{.spec.clusterIP}'
```

**C. CoreDNS configuration error**:
```bash
# Check for syntax errors in Corefile
kubectl get configmap coredns -n kube-system -o yaml

# Validate by checking CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns | grep -i error
```

---

### Example 2: External DNS Not Working

**Error**:
```bash
kubectl exec -it test-pod -- nslookup google.com
# Server:    10.96.0.10
# Address 1: 10.96.0.10
# nslookup: can't resolve 'google.com'
```

**Debug Steps**:
```bash
# 1. Check CoreDNS forward configuration
kubectl get configmap coredns -n kube-system -o yaml | grep -A 3 forward

# 2. Test DNS from CoreDNS pod
kubectl exec -it -n kube-system <coredns-pod> -- nslookup google.com

# 3. Check node's DNS configuration
cat /etc/resolv.conf

# 4. Check CoreDNS logs for forwarding errors
kubectl logs -n kube-system -l k8s-app=kube-dns | grep -i forward
```

**Solutions**:

**A. Upstream DNS not reachable**:
```bash
# Test from node
nslookup google.com

# If node DNS works, check CoreDNS forward config
kubectl edit configmap coredns -n kube-system

# Change forward to use public DNS
forward . 8.8.8.8 1.1.1.1
```

**B. Network policy blocking DNS**:
```bash
# Check network policies
kubectl get networkpolicy -A

# Add DNS egress rule
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: UDP
          port: 53
EOF
```
---

### Example 3: CoreDNS Pods CrashLooping

**Error**:
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
# NAME                       READY   STATUS             RESTARTS
# coredns-5d78c9869d-abc123  0/1     CrashLoopBackOff   5
```

**Debug Steps**:
```bash
# 1. Check pod logs
kubectl logs -n kube-system <coredns-pod>

# 2. Check previous logs
kubectl logs -n kube-system <coredns-pod> --previous

# 3. Describe pod
kubectl describe pod -n kube-system <coredns-pod>

# 4. Check events
kubectl get events -n kube-system --sort-by='.lastTimestamp'
```

**Common Causes and Solutions**:

**A. Corefile syntax error**
```bash
# Check logs for syntax errors
kubectl logs -n kube-system <coredns-pod> | grep -i error

# Fix Corefile
kubectl edit configmap coredns -n kube-system

# Restart CoreDNS
kubectl rollout restart deployment coredns -n kube-system
```
**B. Loop detection**:
```bash
# Logs show: "plugin/loop: Loop detected"
# This means CoreDNS is forwarding to itself

# Check node's /etc/resolv.conf
cat /etc/resolv.conf

# If it points to 127.0.0.x, update CoreDNS forward
kubectl edit configmap coredns -n kube-system

# Change:
forward . /etc/resolv.conf
# To:
forward . 8.8.8.8 1.1.1.1
```

**C. Resource limits**:
```bash
# Check resource usage
kubectl top pod -n kube-system -l k8s-app=kube-dns

# Increase limits
kubectl edit deployment coredns -n kube-system

# Update resources:
resources:
  limits:
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

---

## Best Practices

1. **Monitor CoreDNS**: Set up alerts for CoreDNS pod failures
2. **Scale appropriately**: Run at least 2 replicas for HA
3. **Tune cache**: Increase cache TTL for stable services
4. **Use FQDN**: Use fully qualified names for cross-namespace communication
5. **Test DNS**: Include DNS tests in application health checks
6. **Backup Corefile**: Keep a backup of custom CoreDNS configurations
7. **Resource limits**: Set appropriate CPU and memory limits
8. **Log monitoring**: Monitor CoreDNS logs for errors and warnings

---














