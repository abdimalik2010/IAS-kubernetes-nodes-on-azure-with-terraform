#!/bin/bash

# Specify the IP address of the master node
MASTER_IP=$(terraform output master-node-ip)

# In Bash, you can remove the quotation marks from the string "192.168.1.1" using the sed command or using parameter substitution.
ip_address="\"$MASTER_IP\""
ip_address=$(echo $ip_address | sed 's/"//g')


# Join command for worker nodes
JOIN_COMMAND=$(ssh -i ~/.ssh/id_rsa kroo@$ip_address "kubeadm token create --print-join-command")

# Execute the join command on the worker nodes
worker_ip=$(terraform output worker-node-ip)

ip_worker="\"$worker_ip\""
ip_worker=$(echo $worker_ip | sed 's/"//g')


sudo ssh -i ~/.ssh/id_rsa kroo@$ip_worker "$JOIN_COMMAND"
#ssh <worker_node2_ip> "$JOIN_COMMAND"
#ssh <worker_node3_ip> "$JOIN_COMMAND"



