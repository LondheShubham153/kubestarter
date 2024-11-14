# Kubernetes persistent volumes and persistent volume claim on Minikube Cluster

### In this demo, we will see how to persist data of a kubernetes pods using persistent volume on minikube cluster.

### Pre-requisites to implement this project:
-  Create 1 virtual machine on AWS with 2 CPU, 4GB of RAM (t2.medium)
- Setup minikube on it <a href="https://github.com/LondheShubham153/kubestarter/blob/main/minikube_installation.md">Minikube setup</a>.

#

### What we are going to implement:
- In this demo, we will create persistent volumes (PV) and persistent volume claim (PVC) to persist the data of an application so that it can be restored if our application crashes.
#
## Steps to implement ingress:

<b>1) Create minikube cluster as mentioned in pre-requisites :</b>

#
<b>2) Check minikube cluster status and nodes :</b>
```bash
minikube status
kubectl get nodes
```
#
<b>3) Create persistent volume yaml file :</b>
```bash
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nginx-pv
  labels:
    env: dev
spec:
  storageClassName: standard
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/home/ubuntu/data"
```

#
<b>4) Apply persistent volume :</b>
```bash
kubectl apply -f PersistentVolume.yaml
```
![image](https://github.com/user-attachments/assets/035b2b2b-254a-417e-a701-19966a76f559)

#
<b>5) Create one more yaml file for persistent volume claim :</b>
```bash
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nginx-pv-claim
spec:
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
```

#
<b>6) Apply persistent volume claim :</b>
```bash
kubectl apply -f PersistentVolumeClaim.yaml
```
![image](https://github.com/user-attachments/assets/dc148d34-92f8-4842-91fb-831b11a40890)

#
<b>7) Create a simple nginx pod yaml to attach volume :</b>
```bash
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  volumes:
    - name: nginx-storage
      persistentVolumeClaim:
        claimName: nginx-pv-claim
  containers:
    - name: nginx-container
      image: nginx
      ports:
        - containerPort: 80
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: nginx-storage
```

#
<b>8) Apply Pod yaml file :</b>
```bash
kubectl apply -f Pod.yaml
```
![image](https://github.com/user-attachments/assets/959783f2-3499-42eb-adf5-b2bfc5b4d374)

#
<b>9) Now exec into the above the created pod i.e. nginx :</b>
```bash
kubectl exec -it <pod> -- sh
```
![image](https://github.com/user-attachments/assets/045c63ca-b522-417b-adde-560a35217e14)

#
<b>10) Go to the path /usr/share/nginx/html and do <mark>ls -lrt</mark> :</b>
```bash
cd /usr/share/nginx/html
```
![image](https://github.com/user-attachments/assets/65a1c51b-744e-4bf6-817f-7402029812ce)

<mark> In the above screenshot, there is no files under /usr/share/nginx/html path</mark>

#
<b>11) Now let's create a file under /usr/share/nginx/html path :</b>
```bash
echo "Hello from nginx pod" > nginx-pod.txt
```
![image](https://github.com/user-attachments/assets/d5a51332-65ba-43aa-b663-a8dd76a10713)

#
<b>12) Now exit from the pod and ssh into the minikube host :</b>
```bash
exit
```
```bash
minikube ssh
```
![image](https://github.com/user-attachments/assets/b5c63a04-174f-4c47-ae3c-5a8828595537)

#
<b>13) Now go the path which you mentioned in PersistentVolume.yaml. In our case it is  <mark>/home/ubuntu/data</mark> and check if the file is present or not :</b>
```bash
cd /home/ubuntu/data
ls -lrt
```
![image](https://github.com/user-attachments/assets/b73ca5a9-93d4-4509-8c6d-48d145843ddb)

#
<b>14) Now let's create one more file under /home/ubuntu/data inside minikube host :</b>
```bash
echo "Hello from minikube host pod" > minikube-host-pod.txt
```
![image](https://github.com/user-attachments/assets/d046ca50-62d4-4ad5-8e9d-e8ef5ed1721c)

#
<b>15) At last, go to nginx pod and check if minikube-host-pod.txt file is present or not :</b>
```bash
kubectl exec -it <pod> -- sh
```
```bash
cd /usr/share/nginx/html
ls -lrt
```
![image](https://github.com/user-attachments/assets/9294b05b-ba25-4b6f-b010-5842d1736ed7)

#
Congratulations, you have done it 
<mark>Happy Learning :) </mark>
