## Taints and Tolerations in Kubernetes

### What are Taints amd Tolerations ?
- Taints and tolerations are a mechanism in Kubernetes that allows you to control which pods can be scheduled on specific nodes. 
- They work together to ensure pods are not placed on inappropriate nodes.

### How it works ?
- By default, pods cannot be scheduled on tainted nodes unless they have a special permission called toleration.
- A pod will only be allocated to a node when a toleration on the pod corresponds with the taint of the node.

---

### Implementation of Taints and Tolerations:
#
- Taint a node
```bash
kubectl taint nodes node1 prod=true:NoSchedule
```
<mark>Note</mark>: The above command will taint the node1 with key "prod", without the appropriate tolerations no pods will schedule to node1.

To remove the taint , add - at the end of the command
```bash
kubectl taint nodes node1 prod=true:NoSchedule-
```

- Try to apply the below manifest
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: nginx
  name: nginx
spec:
  containers:
  - image: nginx
    name: nginx
```

Have you noticed pod is in pending state ? Why this is so ? - It's because we have applied taint to node1 but we haven't applied toleration to the nginx pod.

- Now copy the below code and try to deploy it

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: nginx
  name: nginx
spec:
  containers:
  - image: nginx
    name: nginx
  tolerations:
  - key: "prod"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
```
>Note: This pod specification defines a toleration for the "prod" taint with the effect "NoSchedule." This allows the pod to be scheduled on tainted nodes.
