#!/bin/env bash

# S3 Bucket Size Analyzer and Cost Estimator for 30 days
# Author: x.com/aarongxa
# Last Updated: 3/23/24

# This script fetches the sizes of all S3 buckets in GB using CloudWatch metrics
# CloudWatch metrics are utilized for efficiency, especially with large buckets
# The script then estimates monthly costs based on the standard storage class pricing

s3_buckets=$(aws s3api list-buckets --query 'Buckets[*].Name' --output text)
for current_bucket in $s3_buckets; do
    bucket_region=$(aws s3api get-bucket-location --bucket $current_bucket --query 'LocationConstraint' --output text)
    if [ "$bucket_region" == "None" ]; then
        bucket_region="us-east-1"
    fi
    
    # Fetch bucket size from CloudWatch
    bucket_size_bytes=$(aws cloudwatch get-metric-statistics \
        --region $bucket_region \
        --namespace AWS/S3 \
        --metric-name BucketSizeBytes \
        --dimensions Name=BucketName,Value=$current_bucket Name=StorageType,Value=StandardStorage \
        --start-time $(date -u -d "-1 day" +%Y-%m-%dT00:00:00Z) \
        --end-time $(date -u +%Y-%m-%dT00:00:00Z) \
        --period 86400 \
        --statistics Average \
        --unit Bytes \
        --output text \
        --query 'Datapoints[0].Average')
    
    # Convert bytes to GB
    bucket_size_gb=$(echo "scale=2; $bucket_size_bytes / 1024 / 1024 / 1024" | bc)
    
    # Calculate estimated monthly cost (assuming $0.023 per GB)
    estimated_monthly_cost=$(echo "scale=2; $bucket_size_gb * 0.023" | bc | awk '{printf "%.2f\n", $0}')
    
    # Output results
    echo "$current_bucket: $bucket_size_gb GB | \$$estimated_monthly_cost USD/Month"
done
