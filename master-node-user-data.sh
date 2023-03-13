#! /bin/bash

# Check first if the server configured correctly and the network security group configured accordinly
sudo apt update && sudo apt upgrade
sudo apt install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
echo "<h1>Helo from master-node-server</h1>" | sudo tee /var/www/html/index.html

# How To Setup Kubernetes Cluster on Ubuntu using Kubeadm

# Step 1

# .1 Disable swap & add kernel settings

sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 2. Enable iptables Bridged Traffic on all the Nodes

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF


# Apply sysctl params without reboot

sudo sysctl --system


# Step 2) Install containerd run time

# install containerd, first install its dependencie

sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates


# Enable docker repository

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Now, run following apt command to install containerd

sudo apt update
sudo apt install -y containerd.io

# Configure containerd so that it starts using systemd as cgroup.

containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

# Restart and enable containerd service

sudo systemctl restart containerd
sudo systemctl enable containerd

# Step 3) Add apt repository for Kubernetes and then install Kubernetes components Kubectl, kubeadm & kubelet

# Execute following commands to add apt repository for Kubernetes

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl


## Step 4) Initialize Kubernetes cluster with Kubeadm command

# Now, we are all set to initialize Kubernetes cluster. Run the following Kubeadm command from the master node only.

IPADDR="10.0.1.4" # Update with your IP adress
NODENAME=$(hostname -s)
POD_CIDR="192.244.0.0/16"

# Now, initialize the master node control plane configurations using the following kubeadm command.

sudo kubeadm init --apiserver-advertise-address=$IPADDR  \
--apiserver-cert-extra-sans=$IPADDR  \
--pod-network-cidr=$POD_CIDR \
--node-name $NODENAME \
--ignore-preflight-errors Swap
# Use the following commands from the output to create the kubeconfig in master so that you can use kubectl to interact with cluster API.

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico for policy and flannel (aka Canal) for networking
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/canal.yaml -O

# Issue the following command to install Calico.
kubectl apply -f canal.yaml

# Join the worker nodes

sudo ./join-worker-node.sh 