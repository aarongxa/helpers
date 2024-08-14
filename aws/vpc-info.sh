#!/usr/bin/env bash

# ---------------------------------------------------
#
# Purpose: Displays AWS VPC Info in a pretty format
#
# ----------------------------------------------------

set -e

# Function to print error messages
error() {
    echo "Error: $1" >&2
    exit 1
}

# Function to print usage information
usage() {
    echo "Usage: $0 [VPC_ID]"
    echo "If VPC_ID is not provided, the script will list all VPCs in the current region."
}

# Function to pretty print tabular data
pretty_print_table() {
    column -t -s $'\t'
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    error "AWS CLI is not installed. Please install it to run this script."
fi

# If no argument is provided, list all VPCs
if [ $# -eq 0 ]; then
    echo "Listing all VPCs in the current region:"
    aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table
    exit 0
fi

VPC_ID=$1

# Get VPC details
echo "Fetching details for VPC: $VPC_ID"
vpc_details=$(aws ec2 describe-vpcs --vpc-ids "$VPC_ID" 2>/dev/null) || error "Failed to fetch VPC details. Make sure the VPC ID is correct and you have the necessary permissions."

# Extract and display VPC information
echo "VPC Details:"
echo "$vpc_details" | jq -r '.Vpcs[0] | "VPC ID:\t\(.VpcId)\nCIDR Block:\t\(.CidrBlock)\nState:\t\(.State)\nIs Default:\t\(.IsDefault)\nName:\t\(.Tags[] | select(.Key=="Name").Value)"' | pretty_print_table

# Get and display subnet information
echo -e "\nSubnet Details:"
subnet_details=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID")
echo "$subnet_details" | jq -r '.Subnets[] | [.SubnetId, .CidrBlock, .AvailabilityZone, (.Tags[] | select(.Key=="Name").Value)] | @tsv' | 
    (echo -e "Subnet ID\tCIDR Block\tAvailability Zone\tName" && cat) | pretty_print_table

# Get and display Elastic IP information
echo -e "\nElastic IP Details:"
eip_details=$(aws ec2 describe-addresses --filters "Name=domain,Values=vpc")
echo "$eip_details" | jq -r '.Addresses[] | select(.Domain=="vpc") | [.PublicIp, .AllocationId, .AssociationId // "N/A", .InstanceId // "N/A", .NetworkInterfaceId // "N/A"] | @tsv' | 
    (echo -e "Public IP\tAllocation ID\tAssociation ID\tInstance ID\tNetwork Interface ID" && cat) | pretty_print_table

# Get and display NAT Gateway information
echo -e "\nNAT Gateway Details:"
nat_details=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID")
echo "$nat_details" | jq -r '.NatGateways[] | [.NatGatewayId, .State, .SubnetId, .NatGatewayAddresses[0].PublicIp // "N/A"] | @tsv' | 
    (echo -e "NAT Gateway ID\tState\tSubnet ID\tPublic IP" && cat) | pretty_print_table

# Get and display Internet Gateway information
echo -e "\nInternet Gateway Details:"
igw_details=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID")
echo "$igw_details" | jq -r '.InternetGateways[] | [.InternetGatewayId, .Attachments[0].State] | @tsv' | 
    (echo -e "Internet Gateway ID\tState" && cat) | pretty_print_table

# Get and display Route Table information
echo -e "\nRoute Table Details:"
route_table_details=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID")
echo "$route_table_details" | jq -r '.RouteTables[] | "Route Table ID: \(.RouteTableId)\nAssociations: \(.Associations | length)\nRoutes:"'
echo "$route_table_details" | jq -r '.RouteTables[] | .Routes[] | [.DestinationCidrBlock // .DestinationPrefixListId, .GatewayId // .NatGatewayId // .NetworkInterfaceId // .VpcPeeringConnectionId // "Local", .State // "active"] | @tsv' | 
    (echo -e "Destination\tTarget\tState" && cat) | pretty_print_table

echo "Script execution completed."
