# Pod Security Standards and Admission Control

## Overview

Kubernetes uses Pod Security Admission (PSA) to enforce the built‑in Pod Security Standards (PSS) at namespace level to enforce security best practices. 
PSA evaluates Pod create/update requests at admission time and can enforce, warn, or audit policy violations before Pods ever run.

Pod Security Standards (PSS) levels
The three built‑in profiles:

1. Privileged (Unrestricted)
Purpose: No restrictions - allows known privilege escalations

- Allows privileged Pods, host networking, hostPath volumes, Running as root and all other capabilities.

2. Baseline

Purpose: Prevents known privilege escalations while minimizing restrictions

- Minimally restrictive prevents known privilege escalations while allowing most default Pod specs.
- Disallows privileged containers, some host namespaces, and unsafe capabilities.​

3. Restricted
Purpose: Follows pod hardening best practices

- Most secure, based on current Pod hardening best practices.
- Security-critical applications
- Enforces non‑root, seccomp, and limited capabilities and restricts host access patterns.​

## Pod Security Admission

### Admission Modes

Pod Security Admission operates in three modes per namespace:

#### 1. enforce
- **Behavior**: Rejects pods that violate the policy
- **Use**: Production namespaces
- **Effect**: Pod creation fails

#### 2. audit
- **Behavior**: Allows pods but logs violations
- **Use**: Monitoring and gradual rollout
- **Effect**: Pod created, event logged

#### 3. warn
- **Behavior**: Allows pods but shows warning to user
- **Use**: Development and testing
- **Effect**: Pod created, warning displayed

### Namespace Labels

Configure Pod Security using namespace labels:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-namespace
  labels:
    # Enforce restricted standard
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: v1.34
    
    # Audit baseline standard
    pod-security.kubernetes.io/audit: baseline
    pod-security.kubernetes.io/audit-version: v1.34
    
    # Warn on privileged violations
    pod-security.kubernetes.io/warn: baseline
    pod-security.kubernetes.io/warn-version: v1.34
```

Namespaces are labeled to select profile + mode, for example:
```
kubectl label namespace team-a \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=baseline \
  pod-security.kubernetes.io/warn=baseline
```

## Implementing Pod Security

### Step 1: Check Current Configuration

```bash
# Check if Pod Security Admission is enabled
kubectl api-resources | grep podsecurity

# Check existing namespace labels
kubectl get namespaces --show-labels

# Check specific namespace
kubectl get namespace default -o yaml
```

## Admission Controllers

### What are Admission Controllers?

Admission controllers are plugins that intercept requests to the Kubernetes API server before object persistence. They can:
- **Validate**: Check if request meets requirements
- **Mutate**: Modify the request
- **Reject**: Deny the request

### Common Admission Controllers

#### 1. PodSecurity (Validating)
- Enforces Pod Security Standards

#### 2. NamespaceLifecycle (Validating)
- Prevents creation of objects in terminating namespaces
- Ensures system namespaces cannot be deleted

#### 3. LimitRanger (Validating)
- Enforces resource limits on pods and containers
- Applies default limits if not specified

#### 4. ResourceQuota (Validating)
- Enforces resource quotas per namespace
- Prevents resource exhaustion

#### 5. ServiceAccount (Mutating)
- Automatically adds ServiceAccount to pods
- Mounts ServiceAccount token

#### 6. DefaultStorageClass (Mutating)
- Adds default StorageClass to PVCs
- Only if no StorageClass specified

#### 7. MutatingAdmissionWebhook (Mutating)
- Calls external webhooks to mutate objects
- Used by service meshes, policy engines

#### 8. ValidatingAdmissionWebhook (Validating)
- Calls external webhooks to validate objects
- Used for custom policies

### Checking Enabled Admission Controllers
```
# Check enabled admission controllers
kubectl exec -n kube-system kube-apiserver-<node> -- kube-apiserver -h | grep enable-admission-plugins
```
---

## Troubleshooting Admission Errors

### Common Error Patterns

#### Example 1 – HostPath blocked by restricted policy

Error:
```
Error from server (Forbidden): error when creating "pod.yaml": 
pods "nginx" is forbidden: violates PodSecurity "restricted:latest": 
hostPath volumes are not allowed
```
Cause: restricted profile disallows hostPath because it can expose the node filesystem.

Problem Pod:
```yaml
spec:
  volumes:
  - name: host-logs
    hostPath:
      path: /var/log
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: host-logs
      mountPath: /logs
```

Solution: Pod (using PVC instead of hostPath):
```yaml
spec:
  volumes:
  - name: app-logs
    persistentVolumeClaim:
      claimName: app-logs-pvc
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: app-logs
      mountPath: /logs
```

**Debugging Steps:**

```bash
# Check namespace Pod Security labels
kubectl get namespace <namespace> -o yaml | grep pod-security

# Try with warn mode first
kubectl label namespace <namespace> \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/warn=restricted \
  --overwrite

# Create pod and see warnings
kubectl apply -f pod.yaml
```

#### Example 2 : ResourceQuota Exceeded

**Error Message:**
```
Error from server (Forbidden): pods "my-pod" is forbidden: 
exceeded quota: compute-quota, requested: requests.cpu=2, used: requests.cpu=8, limited: requests.cpu=10
```

**Solution:**
```bash
# Check quota
kubectl get resourcequota -n <namespace>
kubectl describe resourcequota compute-quota -n <namespace>

# Reduce pod resources or increase quota
kubectl edit resourcequota compute-quota -n <namespace>
```
---

#### Example 3: LimitRange Violation

**Error Message:**
```
Error from server (Forbidden): pods "my-pod" is forbidden: 
maximum cpu usage per Container is 2, but limit is 4
```

**Solution:**
```bash
# Check LimitRange
kubectl get limitrange -n <namespace>
kubectl describe limitrange <limitrange-name> -n <namespace>

# Adjust pod resources
spec:
  containers:
  - name: nginx
    resources:
      limits:
        cpu: "2"
        memory: "2Gi"
```
### Debugging Workflow

```bash
# 1. Check admission error details
kubectl apply -f pod.yaml --dry-run=server -o yaml

# 2. Check namespace Pod Security labels
kubectl get namespace <namespace> -o yaml

# 3. Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# 4. Check API server logs
kubectl logs -n kube-system kube-apiserver-<node>

# 5. Test with different security levels
kubectl label namespace <namespace> \
  pod-security.kubernetes.io/enforce=privileged \
  --overwrite

# 6. Gradually increase restrictions
kubectl label namespace <namespace> \
  pod-security.kubernetes.io/enforce=baseline \
  --overwrite
```
---

## Exam Tips

1. **Know the Three Standards**: Privileged, Baseline, Restricted
2. **Understand Modes**: enforce, audit, warn
3. **Label Format**: `pod-security.kubernetes.io/<mode>: <level>`
4. **Common Fixes**: runAsNonRoot, drop capabilities, seccomp profile
5. **Debugging**: Use `--dry-run=server` to test
6. **Quick Fix**: Temporarily set to privileged, then fix and restore
7. **Check Events**: `kubectl get events` shows admission errors
