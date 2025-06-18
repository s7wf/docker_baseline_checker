# Docker Baseline Checker

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)
![Shell](https://img.shields.io/badge/shell-bash-lightgrey)

An automated BASH script to enforce Docker security standards. It lints Dockerfiles for best practices, builds the image, and scans it for high-severity vulnerabilities, with an option to email a report to a security distribution list.

## Overview

In a modern CI/CD pipeline, ensuring that Docker images are secure and well-constructed is crucial. This script provides a simple yet effective baseline security check that can be easily integrated into any workflow. It uses two popular open-source tools:

* **Hadolint**: To lint the `Dockerfile` against a set of best-practice rules.
* **Trivy**: To scan the built image for known OS and package vulnerabilities.

The script is designed to fail a CI/CD job if the Dockerfile is poorly written or if high-severity vulnerabilities are discovered, providing fast feedback to developers.

## Features

-   **Dockerfile Linting**: Checks for common mistakes and enforces best practices using `hadolint`.
-   **Vulnerability Scanning**: Scans Docker images for `HIGH` and `CRITICAL` severity vulnerabilities with `Trivy`.
-   **Automated Reporting**: Generates a clean report of any vulnerabilities found.
-   **Email Notifications**: Automatically sends the vulnerability report to a configured email address.
-   **CI/CD Friendly**: Exits with a non-zero status code upon failure, making it easy to integrate into automated pipelines.
-   **Easy to Configure**: Key variables like the recipient email address are easily configurable at the top of the script.

## Prerequisites

Before running this script, you must have the following tools installed and available in your `PATH`:

* [**Docker**](https://www.docker.com/get-started)
* [**Hadolint**](https://github.com/hadolint/hadolint#install)
* [**Trivy**](https://github.com/aquasecurity/trivy#installation)
* **`mailutils`**: Or another command-line mail client that provides the `mail` command. You must also have a configured Mail Transfer Agent (MTA) like Postfix or SSMTP for email sending to work.

## Installation

1.  Clone the repository or download the script.
    ```sh
    git clone [https://github.com/your-username/docker-baseline-checker.git](https://github.com/your-username/docker-baseline-checker.git)
    cd docker-baseline-checker
    ```
2.  Make the script executable:
    ```sh
    chmod +x docker-baseline-checker.sh
    ```

## Usage

Run the script from your terminal with the path to your Dockerfile and a desired image name as arguments.

```sh
./docker-baseline-checker.sh <path/to/Dockerfile> <image:tag>

Example Scenarios
1. Scanning a "Clean" Dockerfile
This command should pass all checks and exit successfully.

./docker-baseline-checker.sh test/Dockerfile.clean clean-app:1.0

2. Scanning a "Vulnerable" Dockerfile
This command will find high-severity vulnerabilities and attempt to send a notification email before exiting with an error.

./docker-baseline-checker.sh test/Dockerfile.vulnerable vulnerable-app:1.0

How It Works
Input Validation: The script first checks that it has received the two required arguments: a Dockerfile path and an image:tag.

Linting: It runs hadolint on the specified Dockerfile. If linting fails, the script exits immediately.

Image Build: If linting is successful, it proceeds to build the Docker image using docker build.

Scanning: The script uses Trivy to scan the newly built image, filtering for HIGH and CRITICAL severity issues. The results are saved to a temporary report file.

Reporting & Notification:

If the report is empty (no high-severity vulnerabilities), the script reports success and exits cleanly.

If vulnerabilities are found, the script sends the report as an email attachment to the configured security address and then exits with an error code to fail the build.

Configuration
You can configure the notification email address by editing the variables at the top of the docker-baseline-checker.sh script:

# The email address for security notifications.
SECURITY_DISTRO="security-alerts@example.com"

# The subject line for the vulnerability report email.
EMAIL_SUBJECT="High-Severity Vulnerability Report for Docker Image"

Interactive Simulation
Don't have the dependencies installed? You can try out a live, web-based simulation of this script to see how it behaves with both clean and vulnerable Dockerfiles.

(Link to your interactive canvas/simulation would go here)

Contributing
Contributions are welcome! If you have suggestions for improvements, please feel free to fork the repository, make your changes, and submit a pull request.

Fork the Project

Create your Feature Branch (git checkout -b feature/AmazingFeature)

Commit your Changes (git commit -m 'Add some AmazingFeature')

Push to the Branch (git push origin feature/AmazingFeature)
5
