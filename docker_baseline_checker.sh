#!/bin/bash

# ==============================================================================
# Docker Baseline Checker
#
# Description:
#   This script automates the process of checking Dockerfiles for best
#   practices and scanning the resulting images for security vulnerabilities.
#   It performs two main functions:
#     1. Lints the specified Dockerfile using 'hadolint'.
#     2. Builds the Docker image and scans it for 'HIGH' or 'CRITICAL'
#        severity vulnerabilities using 'Trivy'.
#
#   If high-severity vulnerabilities are detected, a report is generated and
#   emailed to a designated security distribution list.
#
# Usage:
#   ./docker-baseline-checker.sh <path/to/Dockerfile> <image:tag>
#
# Prerequisites:
#   - Docker engine must be installed and running.
#   - 'hadolint' must be installed (e.g., 'brew install hadolint' or download binary).
#   - 'Trivy' must be installed (e.g., 'brew install trivy' or download binary).
#   - 'mailutils' or a similar package that provides the 'mail' command must be
#     installed and configured with a working Mail Transfer Agent (MTA) like
#     Postfix or ssmtp for email notifications.
#
# ==============================================================================

# --- Configuration ---

# The email address for security notifications.
# Replace with your actual security team's distribution list.
SECURITY_DISTRO="security-alerts@example.com"

# The subject line for the vulnerability report email.
EMAIL_SUBJECT="High-Severity Vulnerability Report for Docker Image"

# --- Script Functions ---

# Displays usage information and exits the script.
usage() {
  echo "Usage: $0 <Dockerfile> <image_name>"
  echo "  <Dockerfile>: Path to the Dockerfile to be linted and built."
  echo "  <image_name>: Name and tag for the Docker image (e.g., my-app:latest)."
  exit 1
}

# --- Main Script Logic ---

# 1. Validate Input
# Check if the correct number of arguments (2) is provided.
if [ "$#" -ne 2 ]; then
  echo "ERROR: Invalid number of arguments."
  usage
fi

DOCKERFILE=$1
IMAGE_NAME=$2
# Temporary file to store the Trivy scan report.
TRIVY_REPORT_FILE="/tmp/trivy_report_$(date +%s).txt"

# Check if the specified Dockerfile exists.
if [ ! -f "$DOCKERFILE" ]; then
    echo "ERROR: Dockerfile not found at '$DOCKERFILE'"
    exit 1
fi

# 2. Lint Dockerfile
echo "INFO: Linting Dockerfile '$DOCKERFILE' with hadolint..."
if ! hadolint "$DOCKERFILE"; then
  echo "ERROR: Dockerfile linting failed. Please fix the reported issues before proceeding."
  exit 1
fi
echo "INFO: Dockerfile linting completed successfully."
echo "--------------------------------------------------"

# 3. Build Docker Image
echo "INFO: Building Docker image '$IMAGE_NAME' from '$DOCKERFILE'..."
if ! docker build -t "$IMAGE_NAME" -f "$DOCKERFILE" .; then
  echo "ERROR: Docker image build failed."
  exit 1
fi
echo "INFO: Docker image build successful."
echo "--------------------------------------------------"

# 4. Scan Image with Trivy
echo "INFO: Scanning image '$IMAGE_NAME' for HIGH and CRITICAL vulnerabilities..."
# Run Trivy scan, filter for HIGH/CRITICAL severities, and direct output to the report file.
# --exit-code 0 ensures the script doesn't stop here if vulns are found; we handle it.
# --no-progress cleans up the output.
trivy image --severity HIGH,CRITICAL --exit-code 0 --no-progress "$IMAGE_NAME" > "$TRIVY_REPORT_FILE"

# 5. Analyze Report and Notify
# Check if the report contains any vulnerabilities other than the summary total.
# The 'tail -n +4' skips the header lines of the Trivy report.
if [ "$(tail -n +4 "$TRIVY_REPORT_FILE" | grep -c .)" -eq 0 ]; then
  echo "INFO: Success! No high or critical severity vulnerabilities found."
  rm "$TRIVY_REPORT_FILE"
  exit 0
else
  echo "WARNING: High-severity vulnerabilities were found in image '$IMAGE_NAME'."
  echo "INFO: Preparing and sending vulnerability report to $SECURITY_DISTRO..."

  # Construct the email body.
  EMAIL_BODY="High-severity vulnerabilities were detected in the Docker image '$IMAGE_NAME'.

Please review the attached Trivy report for details and take appropriate action.
  "

  # Send the email with the report as an attachment.
  if echo -e "$EMAIL_BODY" | mail -s "$EMAIL_SUBJECT" -A "$TRIVY_REPORT_FILE" "$SECURITY_DISTRO"; then
    echo "INFO: Vulnerability report successfully sent to $SECURITY_DISTRO."
  else
    # This might fail if 'mail' is not configured correctly.
    echo "ERROR: Failed to send the vulnerability report email."
    echo "INFO: Displaying report content below:"
    cat "$TRIVY_REPORT_FILE"
  fi

  # Clean up the temporary report file.
  rm "$TRIVY_REPORT_FILE"
  # Exit with an error code to signal failure in CI/CD environments.
  exit 1
fi
