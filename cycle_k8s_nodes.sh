#!/bin/bash
# SET YOUR AWS_REGION and ASG_NAME
# SCRIPT NOT TESTED AS OF 4/8/23

# Set the AWS region and the name of the Auto Scaling group (ASG) that manages the worker nodes
AWS_REGION="us-east-1"
ASG_NAME="my-worker-nodes-asg"

# Get the initial list of nodes
nodes=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')

# Print the list of nodes scheduled for upgrade
echo "Nodes scheduled for upgrade: $nodes"

for node in $nodes; do
  echo "Processing node: $node"

  # Cordon the node
  kubectl cordon $node

  # Drain the node
  kubectl drain $node --ignore-daemonsets --delete-emptydir-data

  # Get the instance ID of the EC2 instance corresponding to the node
  instance_id=$(kubectl get node $node -o jsonpath='{.spec.providerID}' | cut -d '/' -f 5)

  # Terminate the EC2 instance
  aws ec2 terminate-instances --instance-ids $instance_id --region $AWS_REGION

  # Wait for the node to be removed from the cluster
  while kubectl get node $node &>/dev/null; do
    echo "Waiting for node $node to be removed from the cluster..."
    sleep 10
  done

  # Wait for a new node to join the cluster
  while [ "$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}' | wc -w)" -le "${#nodes[@]}" ]; do
    echo "Waiting for a new node to join the cluster..."
    sleep 10
  done

  # Update the list of nodes
  nodes=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')
done

echo "All nodes have been successfully cycled."
