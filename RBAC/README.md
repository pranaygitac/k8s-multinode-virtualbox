
# 🧱 Kubernetes Cluster Setup with kubeadm (Ubuntu 24.04)

This guide for using RBAC in k8s


Steps to Creating Users in Kubernetes with RBAC
1. Create a Client Certificate for the User
# Generate a private key for shubham
openssl genrsa -out shubham.key 2048
# Create a certificate signing request (CSR) for shubham
openssl req -new -key shubham.key -out shubham.csr -subj "/CN=shubham/O=group1"
# Sign the CSR with the Kubernetes CA to get the client certificate
sudo openssl x509 -req -in shubham.csr -CA /etc/kubernetes/pki/ca.crt -CAkey
/etc/kubernetes/pki/ca.key -CAcreateserial -out shubham.crt -days 365
2. Create a Kubeconfig File for the User

use commond below to find your-kubernetes-api-server
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'

kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --embed-certs=true \
  --server=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}') \
  --kubeconfig=shubham.kubeconfig

kubectl config set-credentials shubham --client-certificate=shubham.crt --client-key=shubham.key --embed-certs=true --kubeconfig=shubham.kubeconfig


kubectl config set-context shubham-context --cluster=kubernetes --user=shubham --kubeconfig=shubham.kubeconfig

kubectl config use-context shubham-context --kubeconfig=shubham.kubeconfig

kubectl config current-context --kubeconfig=shubham.kubeconfig

---

