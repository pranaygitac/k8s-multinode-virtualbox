# Kubernetes User Access and RBAC Setup

This guide walks through the steps to:

- Create a client certificate for a user (`shubham`)
- Generate a custom `kubeconfig` file
- Grant read-only access across the cluster
- Grant permission to scale deployments in a specific namespace (`dev`)

---

## ✅ Prerequisites

- A running Kubernetes cluster
- Admin access to the control plane node (where `ca.crt` and `ca.key` exist)
- `openssl` and `kubectl` installed

---

## 🔐 Step 1: Create a Client Certificate for User `shubham`

```bash
# Generate a private key
openssl genrsa -out shubham.key 2048

# Create a certificate signing request (CSR)
openssl req -new -key shubham.key -out shubham.csr -subj "/CN=shubham/O=group1"

# Sign the CSR with the Kubernetes CA to get a client certificate
sudo openssl x509 -req -in shubham.csr -CA /etc/kubernetes/pki/ca.crt \
  -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out shubham.crt -days 365
```

---

## 📁 Step 2: Generate a Kubeconfig for `shubham`

```bash
# Get Kubernetes API server address
API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# Set up kubeconfig
use commond below to find your-kubernetes-api-server
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'

kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --embed-certs=true \
  --server=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}') \
  --kubeconfig=shubham.kubeconfig

kubectl config set-credentials shubham --client-certificate=shubham.crt --client-key=shubham.key --embed-certs=true --kubeconfig=shubham.kubeconfig


kubectl config set-context shubham-context --cluster=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}') --user=shubham --kubeconfig=shubham.kubeconfig

kubectl config use-context shubham-context --kubeconfig=shubham.kubeconfig

kubectl config current-context --kubeconfig=shubham.kubeconfig

```

---

## 📂 Step 3: Install the Kubeconfig in User's Home

```bash
# Copy kubeconfig to user's .kube directory
mkdir -p /home/shubham/.kube
cp shubham.kubeconfig /home/shubham/.kube/config
chown -R shubham:shubham /home/shubham/.kube
chmod 700 /home/shubham/.kube
chmod 600 /home/shubham/.kube/config
```

Now `shubham` can simply run `kubectl` without using the `--kubeconfig` flag.

---

## 🔐 Step 4: Grant Read-Only Cluster Access (Optional)

```bash
# Grant view-only access to all namespaces
kubectl create clusterrolebinding shubham-view \
  --clusterrole=view \
  --user=shubham
```

This allows `shubham` to get, list, and watch all resources but not modify anything.

---

## 📈 Step 5: Grant Permission to Scale Deployments in Namespace `dev`

### 1. Create a Role

```yaml
# scale-deployment-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scale-deployments
  namespace: dev
rules:
  - apiGroups: ["apps"]
    resources: ["deployments/scale"]
    verbs: ["get", "update", "patch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list"]
```

Apply it:

```bash
kubectl apply -f scale-deployment-role.yaml
```

---

### 2. Bind the Role to `shubham`

```yaml
# scale-deployment-rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: shubham-scale-deployments
  namespace: dev
subjects:
  - kind: User
    name: shubham
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: scale-deployments
  apiGroup: rbac.authorization.k8s.io
```

Apply it:

```bash
kubectl apply -f scale-deployment-rolebinding.yaml
```

---

## ✅ Verification

Switch to user `shubham` and run:

```bash
# Read-only access check
kubectl get pods --all-namespaces

# Scale deployment in dev namespace
kubectl scale -n dev deployment static-ui --replicas=3
```

Both commands should succeed if the configuration and permissions are correct.

---

## 🧹 Cleanup (Optional)

```bash
kubectl delete clusterrolebinding shubham-view
kubectl delete rolebinding shubham-scale-deployments -n dev
kubectl delete role scale-deployments -n dev
```

## Tips 
add below command in your ~/.bashrc so that kubectl use appropriate config based on user

```bash
unset KUBECONFIG
export KUBECONFIG=$HOME/.kube/config
echo "KUBECONFIG is changed"
```

---

## 📘 References

- [Kubernetes RBAC Docs](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Client Certificate Authentication](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#x509-client-certs)

## 🔥 Purging User `shubham` from the Cluster

To completely remove all access and references to the user `shubham`, follow the steps below.

### 1. 🧹 Delete RoleBindings (Namespace Scoped)

```bash
# List all RoleBindings involving 'shubham'
kubectl get rolebindings --all-namespaces | grep shubham

# Delete specific RoleBinding
kubectl delete rolebinding shubham-scale-deployments -n dev
```

### 2. 🧹 Delete ClusterRoleBindings

```bash
kubectl get clusterrolebindings | grep shubham
kubectl delete clusterrolebinding shubham-view
```

### 3. 🔐 Delete Certificates and Kubeconfig Files

```bash
# Delete generated certs and keys
rm -f shubham.crt shubham.key shubham.csr shubham.kubeconfig shubham.srl

# Remove from user's home directory if copied there
rm -rf /home/shubham/.kube
```

### 4. 🗑 Delete Roles (If Specific to User)

```bash
kubectl delete role scale-deployments -n dev
```

### 5. ❌ Remove Kubeconfig User and Context Entries (Optional)

```bash
kubectl config unset users.shubham
kubectl config unset contexts.shubham-context
```

### ✅ Verification

Ensure the user no longer has any access:

```bash
kubectl auth can-i get pods --as=shubham
# Expected output: no
```
