#!/usr/bin/env bash

# This script identifies unused Elastic Load Balancers (ELBs) across AWS accounts and regions.
# It can process all accounts and regions, only the active account and region, or all accounts with only US and EU regions.
# An ELB is considered unused if it has no registered instances.

# Function to process a single account and region
process_account_region() {
    local account=$1
    local region=$2
    local unused_elbs=()
    
    # Get all ELBs in the region
    elbs=$(aws elb describe-load-balancers --region $region --query 'LoadBalancerDescriptions[*].LoadBalancerName' --output text 2>/dev/null)
    if [ $? -ne 0 ]; then
        return
    fi
    for elb in $elbs; do
        # Check if the ELB has any instances
        instance_count=$(aws elb describe-instance-health --load-balancer-name $elb --region $region --query 'length(InstanceStates)' --output text 2>/dev/null)
        if [ $? -eq 0 ] && [ "$instance_count" -eq 0 ]; then
            unused_elbs+=("$elb")
        fi
    done

    if [ ${#unused_elbs[@]} -gt 0 ]; then
        echo "  Unused ELB found in $region:"
        printf "    %s\n" "${unused_elbs[@]}"
        echo
    fi
}

# Function to process an account
process_account() {
    local profile=$1
    shift
    local regions=("$@")
    
    echo "Processing account: $profile"
    echo "------------------------------"
    export AWS_PROFILE=$profile
    
    for region in "${regions[@]}"; do
        process_account_region $profile $region
    done
    echo "------------------------------"
}

# Main script
date=$(date "+%a %b %d %H:%M:%S %Z %Y")
echo "Date: $date"

if [ "$1" == "all" ]; then
    # Get all profiles from AWS config
    profiles=$(aws configure list-profiles)
    
    for profile in $profiles; do
        # Get all regions for the current profile
        regions=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text 2>/dev/null)
        if [ $? -eq 0 ]; then
            process_account $profile $regions
        else
            echo "Error: Unable to list regions for profile $profile"
        fi
    done
elif [ "$1" == "active" ]; then
    # Get active profile and region
    active_profile=$(aws configure get profile)
    active_region=$(aws configure get region)
    
    process_account $active_profile $active_region
elif [ "$1" == "eu-us" ]; then
    # List of US and EU regions
    eu_us_regions=(
        "us-east-1" "us-east-2" "us-west-1" "us-west-2"
        "eu-central-1" "eu-west-1" "eu-west-2" "eu-west-3" "eu-north-1" "eu-south-1"
    )
    
    # Get all profiles from AWS config
    profiles=$(aws configure list-profiles)
    
    for profile in $profiles; do
        process_account $profile "${eu_us_regions[@]}"
    done
else
    echo "Usage: $0 [all|active|eu-us]"
    exit 1
fi

echo "Search completed."
