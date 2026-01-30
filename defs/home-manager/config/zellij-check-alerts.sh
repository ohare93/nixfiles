#!/usr/bin/env bash
# Example alert check script for zjstatus
# This script is called every 5 seconds by zjstatus to check for tasks needing attention
# Customize this to check whatever conditions you need

# Example 1: Check for a flag file
if [ -f "/tmp/zellij-alert" ]; then
    # Read the alert message from the file
    message=$(cat /tmp/zellij-alert)
    echo "#[fg=#F38BA8,bg=#181825,bold] 🔴 ${message}"
    exit 0
fi

# Example 2: Check for running background jobs (commented out)
# job_count=$(jobs -r | wc -l)
# if [ "$job_count" -gt 0 ]; then
#     echo "#[fg=#F9E2AF,bg=#181825,bold] ⚡ ${job_count} jobs"
#     exit 0
# fi

# Example 3: Check a custom condition (commented out)
# if some-command-to-check-status; then
#     echo "#[fg=#F38BA8,bg=#181825,bold] 🔔 Alert!"
#     exit 0
# fi

# No alerts - output nothing
echo ""
