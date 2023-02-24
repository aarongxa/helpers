#!/bin/bash

# Get a list of all EC2 instances
# Note: This script assumes you have AWS_DEFAULT_PROFILE and AWS_DEFAULT_REGION set

instances=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId]' --output text)

# Loop through the list of instances
for instance in $instances; do
    # Get the name and private IP of the current instance
    name=$(aws ec2 describe-instances --instance-ids $instance --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value]' --output text)
    private_ip=$(aws ec2 describe-instances --instance-ids $instance --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)

    # Output the name, instance ID, and private IP of the current instance
    echo "Instance Name: $name"
    echo "Instance ID: $instance"
    echo "Private IP: $private_ip"
    echo ""
done

