#!/bin/bash

# Check if the required arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 DISTRIBUTION_ID PATHS"
    echo "Example: $0 E123EXAMPLE /images/example.jpg"
    exit 1
fi

# Get the distribution ID and paths from the command-line arguments
DISTRIBUTION_ID="$1"
PATHS="$2"

# Create an invalidation and get the invalidation ID from the response
INVALIDATION_ID=$(aws cloudfront create-invalidation --distribution-id "$DISTRIBUTION_ID" --paths "$PATHS" --query 'Invalidation.Id' --output text)

# Check if the invalidation was created successfully
if [ -z "$INVALIDATION_ID" ]; then
    echo "Failed to create invalidation."
    exit 1
fi

# Output the invalidation ID
echo "Invalidation ID: $INVALIDATION_ID"

# Continuously check the status of the invalidation until it is completed
while true; do
    # Get the status of the invalidation
    STATUS=$(aws cloudfront get-invalidation --distribution-id "$DISTRIBUTION_ID" --id "$INVALIDATION_ID" --query 'Invalidation.Status' --output text)

    # Output the current status
    echo "Invalidation status: $STATUS"

    # Check if the invalidation is completed
    if [ "$STATUS" == "Completed" ]; then
        echo "Invalidation completed."
        break
    fi

    # Wait for a few seconds before checking the status again
    sleep 5
done

# Exit the script
exit 0
