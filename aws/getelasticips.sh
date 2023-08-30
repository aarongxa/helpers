#!/usr/bin/env bash

# This script retrieves essential information from AWS for configuration purposes.
# It fetches the AWS account number, determines the appropriate AWS region,
# identifies the default VPC and its name (if tagged), and provides debugging outputs.


# Get AWS Account Number
AWS_ACCOUNT_NUMBER=$(aws sts get-caller-identity --query "Account" --output text)

# Check if AWS_DEFAULT_REGION is set, otherwise use AWS_REGION
if [ -z "$AWS_DEFAULT_REGION" ]; then
  if [ -z "$AWS_REGION" ]; then
    # Set a default region
    AWS_REGION="us-west-2"
  else
    AWS_REGION="$AWS_REGION"
  fi
else
  AWS_REGION="$AWS_DEFAULT_REGION"
fi

# Get Default VPC ID
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text --region $AWS_REGION)

# Get VPC Name (assuming it's tagged)
VPC_NAME=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID --query "Vpcs[0].Tags[?Key=='Name'].Value" --output text --region $AWS_REGION)


# Print variables for debugging
echo "AWS_ACCOUNT_NUMBER: $AWS_ACCOUNT_NUMBER"
echo "AWS_REGION: $AWS_REGION"
echo "VPC_ID: $VPC_ID"
echo "VPC_NAME: $VPC_NAME"
echo "ELASTIC_IPS:
aws ec2 describe-addresses --query 'Addresses[*].PublicIp' | tr -d '",[][:blank:]'
