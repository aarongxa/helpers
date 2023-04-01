#!/bin/bash
# Author: Aaron Griffith
# Desc: Cycles accounts in $HOME/.aws/config to check the AWS Support Status

# Define ANSI escape codes for colors
GREEN_COLOR="\033[32m"
RESET_COLOR="\033[0m"

# Get the list of named profiles from the .aws/config file
named_profiles=$(grep -oP '^\[profile \K[^]]+' ~/.aws/config)

# Loop through each named profile
for profile in $named_profiles; do
  # Check if the profile has Business or Enterprise support by attempting to describe Trusted Advisor checks
  # (This operation is only available to accounts with Business or Enterprise support)
  if aws support describe-trusted-advisor-checks --language en --profile "$profile" >/dev/null 2>&1; then
    # If the operation succeeds, the account has Business or Enterprise support
    printf "Account: $profile\n"
    printf "Support Status: ${GREEN_COLOR}Business or Enterprise${RESET_COLOR}\n"
  else
    # If the operation fails, the account does not have Business or Enterprise support
    printf "Account: $profile\n"
    printf "Support Status: Basic or No Access to Support API\n"
  fi
done
