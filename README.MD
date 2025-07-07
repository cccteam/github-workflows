# GitHub Workflows

This repository provides a collection of reusable GitHub Actions workflow templates for use across Cloud Computing Consultants (CCC) projects. The workflows are located in the [`.github/workflows`](.github/workflows) directory.

## Available Workflows

### Go Workflows

- **Golang CI Workflow**
  [`golang-ci.yml`](.github/workflows/golang-ci.yml):
  Runs Go tests, builds, lints, and vulnerability checks for Go projects.

- **Golang Security Scan**
  [`golang-security-scan.yml`](.github/workflows/golang-security-scan.yml):
  Performs security scanning for Go projects using govulncheck, Trivy, and Dependabot alerts. Notifies via Slack and creates GitHub issues for failed jobs.

### Docker Workflows

- **Docker Build & Scan**
  [`docker-build-and-scan.yml`](.github/workflows/docker-build-and-scan.yml):
  Lints Dockerfiles, builds Docker images, and scans them for vulnerabilities using Trivy.

### Terraform Workflows

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

### PR Quality & Security Workflows

- **Semantic Pull Request Title**
  [`semantic-pull-request-title.yml`](.github/workflows/semantic-pull-request-title.yml):
  Enforces semantic PR titles following the [Conventional Commits](https://www.conventionalcommits.org/) format.

- **Closes Issue Check**
  [`closes-issue-check.yml`](.github/workflows/closes-issue-check.yml):
  Ensures pull requests reference and close at least one issue.

- **Secret Scanning**
  [`secrets-scanning.yml`](.github/workflows/secrets-scanning.yml):
  Performs secret scanning on the repository using TruffleHog to detect verified and unknown secrets.

- **Bypass Required Status Checks**
  [`bypass-required-status-checks.yml`](.github/workflows/bypass-required-status-checks.yml):
  A reusable workflow to determine if a pull request's changes are limited to specified bypass paths, enabling conditional skipping of required status checks.

## Usage

To use a reusable workflow in your repository, create a workflow file in your `.github/workflows` directory that references one of the workflows in this repository using the `workflow_call` event.

### Basic Usage Example

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  ci:
    uses: cccteam/github-workflows/.github/workflows/golang-ci.yml@v5.9.0
    with:
      # Workflow-specific inputs here
      go-version: '1.22'
```

### Advanced Example with Multiple Workflows

```yaml
name: Infrastructure CI/CD
on:
  pull_request:
    paths:
      - 'terraform/**'

jobs:
  terraform-fmt:
    uses: cccteam/github-workflows/.github/workflows/terraform-fmt.yml@v5.9.0

  terraform-security:
    uses: cccteam/github-workflows/.github/workflows/trivy-terraform-scan.yml@v5.9.0
    with:
      working-directory: 'terraform'
```

Refer to each workflow file for available inputs, secrets, and configuration options. When referencing workflows, it's recommended to use a specific version tag (e.g., `@v5.9.0`) rather than `@main` to ensure workflow stability.

## Release Management

This repository uses [release-please](https://github.com/googleapis/release-please) for automated releases. When pull requests are merged to the main branch:

1. Release-please automatically determines the next version based on [Conventional Commits](https://www.conventionalcommits.org/)
2. A release PR is created or updated with changelog entries
3. When the release PR is merged, a new GitHub release is published with the version tag

The release process is configured in [release-please-config.json](release-please-config.json), which defines:

- Versioning strategy
- Changelog sections based on commit types
- Package name and management

### Using a Specific Release Version

When referencing workflows in your repository, always use a specific version tag (e.g., `@v5.9.0`) rather than the branch name to ensure stability. Check the [Releases page](https://github.com/cccteam/github-workflows/releases) for the latest version.

## Contributing

Contributions to improve existing workflows or add new ones are welcome! When contributing:

1. Ensure your changes follow the [Conventional Commits](https://www.conventionalcommits.org/) specification for commit messages
2. Include thorough documentation for any new workflow inputs, secrets, or features
3. Test your workflow changes before submitting a PR
4. Reference any related issues in your PR description

### Adding a New Workflow

When adding a new workflow:

1. Place it in the `.github/workflows` directory
2. Follow the naming convention of existing workflows
3. Design it to be reusable with the `workflow_call` event
4. Document all inputs, secrets, and outputs
5. Update the README.md to include the new workflow

## License

See [LICENSE](LICENSE) for details.
