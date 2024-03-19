#!/bin/bash

HEAD_IP="192.168.52.83"
WORKER_IP="192.168.52.74 192.168.52.75"
NFS_IP="192.168.52.44"

ALL_IP=( $HEAD_IP "${WORKER_IP[@]}" )

echo "List of nodes: "
for IP in ${ALL_IP[*]}; do
    echo $IP
done


echo "Set NCCL_IB_DISABLE=1 for all nodes ------------------------------"
for IP in ${ALL_IP[*]}; do
    sshpass -f password ssh jetson@$IP "echo export NCCL_IB_DISABLE=1 >> .bashrc"
    sshpass -f password ssh jetson@$IP "echo NCCL_IB_DISABLE=1 | sudo tee -a /etc/environment"
done

echo "Let the head node ssh into the all nodes at least once so in the future it won't ask about fingerprint ------------------------------"
for IP in ${ALL_IP[*]}; do
    ssh -t jetson:jetson@$HEAD_IP "echo exit | xargs ssh ubuntu@$IP"
done

echo "Set up NFS ------------------------------"
for IP in ${ALL_IP[*]}; do
    sshpass -f password ssh jetson@$IP "if [ ! -d shared ]; then mkdir shared; fi"
done


for IP in ${WORKER_IP[*]}; do
    sshpass -f password ssh jetson@$IP "sudo mount ${NFS_IP}:/mnt/shares /home/ubuntu/shared"
done
echo "NFS set up on the worker nodes"

echo "Clone repos into NFS ------------------------------"
sshpass -f password ssh jetson@$HEAD_IP "if [ ! -d /home/ubuntu/shared/llama ]; then git clone https://github.com/LambdaLabsML/llama.git /home/ubuntu/shared/llama; fi"
sshpass -f password ssh jetson@$HEAD_IP "if [ ! -d /home/ubuntu/shared/llama-dl ]; then git clone https://github.com/chuanli11/llama-dl.git /home/ubuntu/shared/llama-dl; fi"

echo "Install LLAMA dependencies (asynchronously) ------------------------------"
for IP in ${ALL_IP[*]}; do cat dependencies-install.sh | sshpass -f password ssh jetson${IP} & done

wait

echo "All instances are successfully set up 🥳🥳🥳🥳🥳🥳🥳🥳"
