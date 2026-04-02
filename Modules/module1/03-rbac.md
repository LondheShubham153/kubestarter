# RBAC (Role‑Based Access Control)

### Let's understand Role, RoleBinding, ClusterRole, ClusterRoleBinding, ServiceAccount creation/config/troubleshooting

## Overview
RBAC (Role‑Based Access Control) is the authorization mechanism in K8s. That allows you to control who can perform what actions on which resources.

**Core Components:**
- **Role**: Defines permissions within a namespace
- **ClusterRole**: Defines permissions cluster-wide or resuable set of permissions
- **RoleBinding**: Grants Role permissions to subjects in a namespace
- **ClusterRoleBinding**: Grants ClusterRole permissions to subjects cluster-wide
- **ServiceAccount**: Provides identity for processes running in Pods

## ServiceAccounts

### What are ServiceAccounts?

ServiceAccounts provide an identity for processes running in Pods. Every namespace has a default ServiceAccount.

### Examples

### ServiceAccount creation and use

#### Create namespace and ServiceAccount
```
kubectl create namespace dev
kubectl create serviceaccount app-sa -n dev
```

#### Inspect
```
kubectl get sa -n dev
kubectl describe sa app-sa -n dev
```

Use this in a Pod:

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: dev
spec:
  serviceAccountName: app-sa
  containers:
  - name: nginx
    image: nginx
```


### Role and RoleBinding (namespace‑scoped)

Motive: Allow app-sa to list/get/watch Pods only in dev namespace.

**Roles**
```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: dev
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```
**RoleBinding**
```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: dev
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: dev
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
```
```
kubectl apply -f <filename.yaml>
kubectl apply -f <filename.yaml>
```

## ClusterRole and ClusterRoleBinding

Motive: Allow app-sa to list/get/watch Pods in all namespace.

**clusterrole**

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader-cluster
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

**ClusterRoleBinding**

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: pod-reader-cluster-binding
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: dev
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: pod-reader-cluster
```

## Troubleshooting

### Checking Permissions

#### kubectl auth can-i

```bash
# Check if current user can create pods
kubectl auth can-i create pods

# Check if current user can delete deployments in namespace
kubectl auth can-i delete deployments --namespace=production

# Check as another user
kubectl auth can-i get pods --as=jane

# Check as ServiceAccount
kubectl auth can-i list secrets --as=system:serviceaccount:default:app-sa

# List all permissions for current user
kubectl auth can-i --list

# List all permissions in namespace
kubectl auth can-i --list --namespace=production
```
### Examples

#### Example 1: ServiceAccount Cannot Access Resources

**Error:**
```
Error from server (Forbidden): deployments.apps is forbidden: 
User "system:serviceaccount:default:app-sa" cannot list resource "deployments"
```

**Debug:**
```bash
# Check ServiceAccount permissions
kubectl auth can-i list deployments \
  --as=system:serviceaccount:default:app-sa \
  --namespace=default

# Check RoleBindings for ServiceAccount
kubectl get rolebindings -n default -o yaml | grep -A 10 "app-sa"

# Describe ServiceAccount
kubectl describe serviceaccount app-sa -n default
```
**Solution:**

### Create Role and RoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-reader
  namespace: default
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-sa-deployment-reader
  namespace: default
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: default
roleRef:
  kind: Role
  name: deployment-reader
  apiGroup: rbac.authorization.k8s.io
```
#### Example 2: Forbidden - User Cannot Perform Action

**Error:**
```
Error from server (Forbidden): pods is forbidden: 
User "jane" cannot list resource "pods" in API group "" in the namespace "default"
```

**Debug:**
```bash
# Check if user has permission
kubectl auth can-i list pods --as=jane --namespace=default

# Check RoleBindings for user
kubectl get rolebindings -n default -o yaml | grep -A 5 "name: jane"

# Check ClusterRoleBindings for user
kubectl get clusterrolebindings -o yaml | grep -A 5 "name: jane"
```

**Solution:**
```bash
# Create appropriate RoleBinding
kubectl create rolebinding jane-pod-reader \
  --role=pod-reader \
  --user=jane \
  --namespace=default
```

#### Example 3: Multiple Resources:

- To assign roles for multiple resources

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-manager
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

#### Example 4: Missing RoleBinding!

**Problem: No RoleBinding exists for the user**

##### ❌ Incorrect Configuration

```yaml
# Only Role exists, no binding
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```
##### ✅ Correct Configuration

```yaml
# Role definition
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
# RoleBinding to grant permissions to user
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jane-pod-reader
  namespace: default
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

#### Example 5: Incorrect Configuration

**Problem: Wrong API group specified (empty string instead of "apps")**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-manager
  namespace: production
rules:
- apiGroups: [""]  # ❌ WRONG! Deployments are not in core API group
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: bob-deployment-manager
  namespace: production
subjects:
- kind: User
  name: bob
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: deployment-manager
  apiGroup: rbac.authorization.k8s.io
```

### ✅ Correct Configuration

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-manager
  namespace: production
rules:
- apiGroups: ["apps"]  # ✅ CORRECT! Deployments are in "apps" API group
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: bob-deployment-manager
  namespace: production
subjects:
- kind: User
  name: bob
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: deployment-manager
  apiGroup: rbac.authorization.k8s.io
```

### Verification
```bash
# Test permission
kubectl auth can-i create deployments --as=bob --namespace=production
# Output: yes

# Try creating a deployment
kubectl create deployment nginx --image=nginx --as=bob --namespace=production
```

---
