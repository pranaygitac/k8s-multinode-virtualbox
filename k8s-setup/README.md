
# 🧱 Kubernetes Cluster Setup with kubeadm (Ubuntu 24.04)

This guide walks through creating a Kubernetes cluster using `kubeadm`, with a control plane and one worker node on Ubuntu 24.04.

---

## 🖥️ Infrastructure

| Role           | IP Address     | Hostname      |
|----------------|----------------|---------------|
| Control Plane  | `192.168.3.20` | `controlplane`|
| Worker Node    | `192.168.3.21` | `worker`      |

- **Pod Network CIDR**: `10.244.0.0/16`
- **CNI Plugin**: Calico
- **Container Runtime**: containerd with `pause:3.10`

---

## ✅ Prerequisites (Both Nodes)

### 1. Update and Configure `/etc/hosts`
```bash
sudo apt update && sudo apt upgrade -y
```

Edit `/etc/hosts` on both nodes:
```bash
192.168.3.20 controlplane
192.168.3.21 worker
```

---

### 2. Disable Swap
```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

---

### 3. Load Kernel Modules and sysctl
```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

---

## 🐳 Install containerd (Both Nodes)
```bash
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
```

Edit `/etc/containerd/config.toml` and update:
```toml
[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "registry.k8s.io/pause:3.10"
```

Restart:
```bash
sudo systemctl restart containerd
sudo systemctl enable containerd
```

---

## ⚙️ Install Kubernetes Tools (Both Nodes)
```bash
sudo apt install -y apt-transport-https curl gpg
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] \
https://apt.kubernetes.io/ kubernetes-xenial main" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

---

## 🚀 Control Plane Initialization

### 1. Initialize Cluster
```bash
sudo kubeadm init \
  --apiserver-advertise-address=192.168.3.20 \
  --pod-network-cidr=10.244.0.0/16
```

### 2. Setup kubeconfig
```bash
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

---

## 🌐 Install Calico CNI

Download and update Calico configuration:
```bash
curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml -O
```

Edit `calico.yaml`:
```yaml
- name: CALICO_IPV4POOL_CIDR
  value: "10.244.0.0/16"
```

Apply it:
```bash
kubectl apply -f calico.yaml
```

---

## 👷 Join the Worker Node

### 1. Generate join command on control plane:
```bash
kubeadm token create --print-join-command
```

### 2. Run it on the worker node:
```bash
sudo kubeadm join 192.168.3.20:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

---

## ✅ Verify Cluster

Run on control plane:
```bash
kubectl get nodes -o wide
kubectl get pods -A
```


Expected:
```
NAME           STATUS   ROLES           VERSION   INTERNAL-IP
controlplane   Ready    control-plane   v1.31.x   192.168.3.20
worker         Ready    <none>          v1.31.x   192.168.3.21
```

Run on Both:
```bash
sudo systemctl enable kubelet
```

---

Tip: to run pods on control plane , untaint it

```bash
kubectl taint nodes controlplane node-role.kubernetes.io/control-plane:NoSchedule-
#node/controlplane untainted

```

## 🎉 Done!

You've built a secure and functional Kubernetes cluster using kubeadm, Calico CNI, and containerd.

---

## 📁 License

MIT © PranaySawant
