#!/usr/bin/env bash

# TLS Certificate Analyzer for Kubernetes
# Author: @aarongxa

# This script performs the following tasks:
# 1. Retrieves a list of TLS certificates from a Kubernetes cluster in the 'prod' namespace
# 2. Iterates through each certificate, extracting key information
# 3. Displays the Common Name (CN), Issuer, and important dates for each certificate

# Fetch all TLS secrets in the production namespace
tls_secrets=$(kubectl get secrets -n prod --field-selector type=kubernetes.io/tls -o name)

for current_secret in $tls_secrets
do
    echo ""
    echo "Analyzing secret: $current_secret"
    
    # Extract and decode the certificate data
    certificate_data=$(kubectl get $current_secret -n prod -o json | 
                       jq '.data."tls.crt"' | 
                       sed 's/\"//g' | 
                       base64 -d)
    
    # Display certificate details
    echo "$certificate_data" | openssl x509 -noout -subject -issuer -dates
done
