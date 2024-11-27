# Kubernetes RBAC Controller on Minikube Cluster

###  In this demo, we will see how to use RBAC controller for managing access to your Kubernetes resources.
#

## Pre-requisites to implement this project:

- Create 1 virtual machine on AWS with 2 CPU, 4GB of RAM (t2.medium)
- Setup minikube on it Minikube setup
- Check minikube cluster status and nodes :
```bash
minikube status
kubectl get nodes
```
#
### What we are going to implement:
- In this demo, we will create a deployment and services for Apache and with the help of RBAC, we will manage the access.
#

### Steps to implement RBAC:

- First, let's define namespaces.yaml to separate your resources. This helps in organizing and applying RBAC policies.
```bash
# namespaces.yml
apiVersion: v1
kind: Namespace
metadata:
  name: apache-namespace
```
#
- Apply apache deployment :
```bash
# apache-deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache-deployment
  namespace: apache-namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
    spec:
      containers:
      - name: apache
        image: httpd:2.4
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: apache-service
  namespace: apache-namespace
spec:
  selector:
    app: apache
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```
#
- Apply apache-deployment & namespaces.yaml:
```bash
kubectl apply -f apache-deployment.yml
kubectl apply -f namespaces.yml
```
#
- Create Roles and RoleBindings:

  - Role for Managing Apache Deployment.<br>
`We'll create a role that allows managing Apache resources within the apache-namespace.`

```bash
# apache-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: apache-namespace
  name: apache-manager
rules:
- apiGroups: ["", "apps", "extensions"]
  resources: ["deployments", "services", "pods"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```
#
- RoleBinding for Apache Manager
We'll bind the role to a user or service account.
```bash
# apache-rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: apache-manager-binding
  namespace: apache-namespace
subjects:
- kind: User
  name: apache-user # This should be replaced with the actual user name
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: apache-manager
  apiGroup: rbac.authorization.k8s.io
```
#
- Apply apache-role & rolebinding:
```bash
kubectl apply -f apache-role.yaml
kubectl apply -f apache-rolebinding.yaml
```
#
- Create Users (Optional):

**If you are using a Kubernetes distribution that supports user management, you can create users and assign them the respective roles. Here, we'll use basic ServiceAccounts for simplicity.**
```bash
#apache-serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: apache-user
  namespace: apache-namespace
```
#
- Apply the service accounts:
```bash
kubectl apply -f apache-serviceaccount.yaml
```
#

## Verify Roles and RoleBinding

**To cross-verify the RBAC setup, you can perform a series of checks and actions to ensure that the roles and permissions are applied correctly. Here’s how you can do it:**

- Check Roles:
```bash
kubectl get roles -n apache-namespace
```
Ensure apache-manager and nginx-manager roles are listed.
#
- Check RoleBindings:
```bash
kubectl get rolebindings -n apache-namespace
```
Ensure apache-manager-binding and nginx-manager-binding role bindings are listed.
#
### Verify ServiceAccounts
- Check ServiceAccounts:
```bash
kubectl get serviceaccounts -n apache-namespace
```
Ensure apache-user and nginx-user service accounts are listed.

### Test Access Using Impersonation
You can use the 'kubectl auth can-i' command to verify the permissions granted by the roles.

**Test Apache User Permissions:**
```bash
kubectl auth can-i create deployment -n apache-namespace --as=apache-user
kubectl auth can-i get pods -n apache-namespace --as=apache-user
kubectl auth can-i delete service -n apache-namespace --as=apache-user
```
#
**To test denial of permissions outside the namespace:**
```bash
kubectl auth can-i create deployment -n nginx-namespace --as=apache-user
```
#
### Create Test Resources

**Test Apache User Resource Creation:**
```bash
kubectl run apache-test --image=httpd:2.4 -n apache-namespace 
kubectl get pods -n apache-namespace
```
> Verify that the 'apache-test' pod is created in the 'apache-namespace'.

**Clean Up Test Resources**

After verification, clean up the test resources:
Delete Test Pods:
```bash
kubectl delete pod apache-test -n apache-namespace
```
#
## This should provide you with a thorough verification of your RBAC setup, ensuring that the roles and permissions are correctly applied and functioning as intended.

