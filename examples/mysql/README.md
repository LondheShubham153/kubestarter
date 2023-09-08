### Interview Questions:

1. **Explain the deployment pattern you'd use to deploy MySQL on Kubernetes while ensuring data persistence and high availability.**

   Answer: To deploy MySQL on Kubernetes with data persistence and high availability, I'd use a combination of StatefulSets and PersistentVolumeClaims (PVCs). StatefulSets provide unique network identities for each pod, and PVCs ensure data is retained even if pods are restarted or rescheduled.

2. **Describe the role of a Kubernetes StatefulSet when deploying MySQL.**

   Answer: A Kubernetes StatefulSet is the ideal choice for deploying stateful applications like MySQL. It maintains stable network identities for pods, manages ordered scaling, ensures ordered pod termination, and allows data persistence across pod rescheduling.

3. **What is the purpose of using a PersistentVolumeClaim (PVC) when deploying MySQL on Kubernetes?**

   Answer: A PersistentVolumeClaim defines a request for storage resources, and when used with a StorageClass, dynamically provisions PersistentVolumes for pods. For MySQL, PVCs guarantee data persistence by binding the same volume even after pod rescheduling.

4. **Explain the concept of a StorageClass and how it contributes to deploying MySQL on Kubernetes.**

   Answer: A StorageClass is an abstraction that defines the storage provisioner and settings for dynamically creating PersistentVolumes. When deploying MySQL, StorageClass allows automatic provisioning of storage resources for PersistentVolumeClaims, ensuring data persistence.

### Manifest File Examples:

1. **MySQL StorageClass and PersistentVolumeClaim (PVC) Manifests:**

   - **StorageClass** (`mysql-storageclass.yaml`):

     ```yaml
     apiVersion: storage.k8s.io/v1
     kind: StorageClass
     metadata:
       name: mysql-storage
     provisioner: kubernetes.io/no-provisioner
     volumeBindingMode: WaitForFirstConsumer
     ```

   - **PersistentVolumeClaim** (`mysql-pvc.yaml`):

     ```yaml
     apiVersion: v1
     kind: PersistentVolumeClaim
     metadata:
       name: mysql-pvc
     spec:
       storageClassName: mysql-storage
       accessModes:
         - ReadWriteOnce
       resources:
         requests:
           storage: 1Gi
     ```

2. **MySQL Deployment Manifest (`mysql-deployment.yaml`):**

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: mysql-deployment
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: mysql
     template:
       metadata:
         labels:
           app: mysql
       spec:
         containers:
           - name: mysql
             image: mysql:latest
             env:
               - name: MYSQL_ROOT_PASSWORD
                 value: rootpassword
             ports:
               - containerPort: 3306
             volumeMounts:
               - name: mysql-data
                 mountPath: /var/lib/mysql
         volumes:
           - name: mysql-data
             persistentVolumeClaim:
               claimName: mysql-pvc
   ```
