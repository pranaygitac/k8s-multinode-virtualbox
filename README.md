
# 💻 VirtualBox VM Setup for Kubernetes Cluster (Ubuntu 24.04)

This guide details the process to create VirtualBox VMs for a Kubernetes control plane and worker node using a host-only network.

---

## 🛠️ 1. Create Host-Only Network

1. Open **Oracle VirtualBox**.
2. Go to **File > Tools > Network Manager**.
3. Click **Create** a new Host-Only Network.
4. Configure manually:
   - **IPv4 Address**: `192.168.3.1`
   - **IPv4 Network Mask**: `255.255.255.0`
   - **Disable DHCP Server**.
   ![image](https://github.com/user-attachments/assets/bd36d854-eb67-4b01-b623-27c260bf10b9)

5. Save and exit.

---

## 🖥️ 2. Create Control Plane VM

1. Go to **Machine > New**.
2. Name: `controlplane`
3. Type: Linux, Version: Ubuntu (64-bit)
4. Skip unattended installation.
5. Attach ISO: `ubuntu-24.04.2-live-server-amd64.iso`

### VM Settings
- CPU: 2+
- RAM: 2048 MB or more
- Disk: 20 GB
- Network:
  - **Adapter 1**: NAT
  - **Adapter 2**: Host-only (choose the host-only network you created)

---

## ⚙️ 3. Install Ubuntu on VM

1. Start the VM and begin Ubuntu setup.
2. Accept defaults for everything except:

### A. Network Configuration
- Choose adapter with **no IP assigned** (host-only adapter).
- Edit IPv4 method to **Manual**.
- Set:
  - Subnet: `192.168.3.0/24`
  - Address: `192.168.3.20`

   ![image](https://github.com/user-attachments/assets/32e02b6e-7955-4811-85ce-4551e0e786f6)

  ![image](https://github.com/user-attachments/assets/8f245d4f-b1f4-44cc-85b2-03fd58869728)

### B. Install SSH Server
- Check **Install OpenSSH Server** option.

3. Complete the installation and reboot.

---

## 🧑‍💻 4. Create Worker Node VM

Repeat the above steps:
- Name: `worker`
- Set Host-only IP: `192.168.3.21`

---

## 🔐 5. Setup SSH Access from VS Code

### A. Generate SSH Key on Host (Windows)
```bash
ssh-keygen -t rsa -b 4096 -C "pranay@k8s"
```

- Save the key in default location (e.g., `~/.ssh/id_rsa`)

### B. Copy SSH Key to VMs
```bash
ssh-copy-id pranay@192.168.3.20
ssh-copy-id pranay@192.168.3.21
```

If `ssh-copy-id` is not available, manually copy the key:
```bash
cat ~/.ssh/id_rsa.pub | ssh pranay@192.168.3.20 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
cat ~/.ssh/id_rsa.pub | ssh pranay@192.168.3.21 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
```

---

## 🧠 6. VS Code SSH Config (`~/.ssh/config`)

```ssh
Host controlplane
    HostName 192.168.3.20
    User pranay
    IdentityFile ~/.ssh/id_rsa

Host worker
    HostName 192.168.3.21
    User pranay
    IdentityFile ~/.ssh/id_rsa
```

---

## 🚀 7. Connect from VS Code

- Open VS Code.
- Press `F1` → **Remote-SSH: Connect to Host** → select `controlplane` or `worker`.

You're now ready to interact with your VMs from VS Code over SSH.

---
