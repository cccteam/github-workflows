# GitHub Workflows

This repository provides a collection of reusable GitHub Actions workflow templates for use across Cloud Computing Consultants (CCC) projects. The workflows are located in the [`.github/workflows`](.github/workflows) directory.

## Available Workflows

- **Golang CI Workflow**
  [`golang-ci.yml`](.github/workflows/golang-ci.yml):
  Runs Go tests, builds, lints, and vulnerability checks for Go projects.

- **Golang Security Scan**
  [`golang-security-scan.yml`](.github/workflows/golang-security-scan.yml):
  Performs security scanning for Go projects using govulncheck, Trivy, and Dependabot alerts. Notifies via Slack and creates GitHub issues for failed jobs.

- **Docker Build & Scan**
  [`docker-build-and-scan.yml`](.github/workflows/docker-build-and-scan.yml):
  Lints Dockerfiles, builds Docker images, and scans them for vulnerabilities using Trivy.

- **Terraform Format Check**
  [`terraform-fmt.yml`](.github/workflows/terraform-fmt.yml):
  Checks formatting of Terraform files in changed directories.

- **Terraform Docs Generation**
  [`terraform-docs.yml`](.github/workflows/terraform-docs.yml):
  Generates and updates documentation for Terraform modules.

- **Trivy Terraform Scan**
  [`trivy-terraform-scan.yml`](.github/workflows/trivy-terraform-scan.yml):
  Scans changed Terraform files for vulnerabilities, secrets, and misconfigurations using Trivy.

- **Checkov Terraform Scan**
  [`checkov-scan.yml`](.github/workflows/checkov-scan.yml):
  Scans Terraform code for security and compliance issues using Checkov.

- **TFLint Terraform Check**
  [`tflint-terraform-check.yml`](.github/workflows/tflint-terraform-check.yml):
  Runs [TFLint](https://github.com/terraform-linters/tflint) on changed Terraform files to enforce best practices and catch errors.

- **Trunk Check**
  [`trunk-check.yaml`](.github/workflows/trunk-check.yaml):
  Runs [Trunk](https://trunk.io/) checks to enforce code quality and standards.

- **Trunk Nightly Upgrade**
  [`trunk-upgrade.yml`](.github/workflows/trunk-upgrade.yml):
  Automates nightly upgrades of Trunk dependencies.

- **Semantic Pull Request Title**
  [`semantic-pull-request-title.yml`](.github/workflows/semantic-pull-request-title.yml):
  Enforces semantic PR titles.

- **Closes Issue Check**
  [`closes-issue-check.yml`](.github/workflows/closes-issue-check.yml):
  Ensures pull requests reference and close at least one issue.

- **Secret Scanning**
  [`secret-scanning.yml`](.github/workflows/secret-scanning.yml):
  Performs secret scanning on the repository using TruffleHog to detect verified and unknown secrets.

## Usage

To use a workflow, reference it in your repository's workflow YAML using the `workflow_call` event. For example:

```yaml
name: CI
on:
  workflow_call:
    # inputs here

jobs:
  # jobs defined in the reusable workflow will be invoked
```

Refer to each workflow file for available inputs and configuration options.

## Release Management

This repository uses [release-please](https://github.com/googleapis/release-please) for automated releases. See [release-please-config.json](release-please-config.json) for configuration.

## License

See [LICENSE](LICENSE) for details.
