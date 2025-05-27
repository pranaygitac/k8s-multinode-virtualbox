# 🧱 Kubernetes Cluster Setup with kubeadm & Docker (Ubuntu 24.04)

This guide walks through creating a Kubernetes cluster using `kubeadm`, with a control plane and one worker node on Ubuntu 24.04, using **Docker Engine** as the container runtime instead of containerd.

---

## 💻 Infrastructure

| Role          | IP Address     | Hostname       |
| ------------- | -------------- | -------------- |
| Control Plane | `192.168.3.20` | `controlplane` |
| Worker Node   | `192.168.3.21` | `worker`       |

* **Pod Network CIDR**: `10.244.0.0/16`
* **CNI Plugin**: Calico
* **Container Runtime**: Docker Engine with `cri-dockerd`

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

## 🐫 Install Docker Engine (Both Nodes)

```bash
sudo apt install -y ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker
```

---

## 🔧 Install cri-dockerd (Both Nodes)

```bash
sudo apt install -y golang-go

git clone https://github.com/Mirantis/cri-dockerd.git
cd cri-dockerd
mkdir bin
go build -o bin/cri-dockerd

sudo mv bin/cri-dockerd /usr/local/bin/

sudo cp -a packaging/systemd/* /etc/systemd/system
sudo sed -i 's:/usr/bin/cri-dockerd:/usr/local/bin/cri-dockerd:' \
    /etc/systemd/system/cri-docker.service

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket
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

### 1. Pull Kubernetes Images

```bash
sudo kubeadm config images pull --cri-socket=unix:///var/run/cri-dockerd.sock
```

### 2. Initialize Cluster

```bash
sudo kubeadm init \
  --apiserver-advertise-address=192.168.3.20 \
  --pod-network-cidr=10.244.0.0/16 \
  --cri-socket=unix:///var/run/cri-dockerd.sock
```

### 3. Setup kubeconfig

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
sudo kubeadm join 192.168.3.20:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --cri-socket=unix:///var/run/cri-dockerd.sock
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

Tip: to run pods on control plane, untaint it

```bash
kubectl taint nodes controlplane node-role.kubernetes.io/control-plane:NoSchedule-
#node/controlplane untainted
```

---

## 🎉 Done!

You've built a secure and functional Kubernetes cluster using kubeadm, Calico CNI, and Docker Engine with cri-dockerd.

---

## 📁 License

MIT © PranaySawant
