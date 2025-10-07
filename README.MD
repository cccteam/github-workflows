# GitHub Workflows

This repository provides a collection of reusable GitHub Actions workflow templates for use across Cloud Computing Consultants (CCC) projects. The workflows are located in the [`.github/workflows`](.github/workflows) directory.

## Available Workflows

### Angular Workflows

- **Angular CI**
  [`angular-ci.yml`](.github/workflows/angular-ci.yml):
  Runs configurable npm scripts for all Angular projects defined in angular.json. Supports any npm script names defined in package.json with defaults of build and lint.

### Go Workflows

- **Golang CI Workflow**
  [`golang-ci.yml`](.github/workflows/golang-ci.yml):
  Runs Go tests, builds, lints, and vulnerability checks for Go projects.

- **Golang Security Scan**
  [`golang-security-scan.yml`](.github/workflows/golang-security-scan.yml):
  Performs comprehensive security scanning for Go projects using govulncheck, Trivy, Semgrep, and Dependabot alerts. Notifies via Slack and creates GitHub issues for failed jobs. Optionally uploads SARIF reports to GitHub Advanced Security Dashboard for scheduled and manual runs.

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

## Usage

To use a reusable workflow in your repository, create a workflow file in your `.github/workflows` directory that references one of the workflows in this repository using the `workflow_call` event.

### Basic Usage Example

```yaml
name: CI
on:
  push:
    branches: [master]
  pull_request:
    branches: [master]

jobs:
  ci:
    uses: cccteam/github-workflows/.github/workflows/golang-ci.yml@v5.9.0
    with:
      # Workflow-specific inputs here
      go-version: '1.22'
```

### Angular Example

```yaml
name: Angular CI
on:
  push:
    branches: [master]
  pull_request:
    branches: [master]

jobs:
  # Run default checks (build and lint)
  angular-check:
    uses: cccteam/github-workflows/.github/workflows/angular-ci.yml@v5.9.0
    with:
      node-version: '20'
      working-directory: './frontend'

  # Run custom npm scripts
  angular-full-check:
    uses: cccteam/github-workflows/.github/workflows/angular-ci.yml@v5.9.0
    with:
      node-version: '20'
      working-directory: './frontend'
      checks: '["build", "lint", "test", "audit", "format:check"]'

  # Run only specific checks
  angular-build-only:
    uses: cccteam/github-workflows/.github/workflows/angular-ci.yml@v5.9.0
    with:
      checks: '["build"]'
```

#### Common Angular npm Scripts

The Angular CI workflow can run any npm script defined in your `package.json`. Common examples include:

- `build` - Build the application
- `lint` - Run ESLint
- `test` - Run unit tests
- `e2e` - Run end-to-end tests
- `audit` - Security vulnerability scanning
- `format:check` - Code formatting validation
- `typecheck` - TypeScript type checking
- `bundle-analyzer` - Bundle size analysis
- `docs` - Generate documentation

### Security Scanning with SARIF Upload

```yaml
name: Security Scan
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
  workflow_dispatch:

jobs:
  security-scan:
    uses: cccteam/github-workflows/.github/workflows/golang-security-scan.yml@v5.9.0
    with:
      upload-sarif: true  # Upload results to GitHub Security Dashboard
      execute-trivy-scan: true
      execute-dependabot-check: true
      execute-semgrep-scan: true  # Enable Semgrep static analysis
      semgrep-config: auto  # Use auto-detection or specify custom rules (e.g., p/security-audit, p/owasp-top-ten)
    secrets:
      SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}
      SLACK_CHANNEL_ID: ${{ secrets.SLACK_CHANNEL_ID }}
      DEPENDABOT_ALERTS_TOKEN: ${{ secrets.DEPENDABOT_ALERTS_TOKEN }}
```

**Note:** SARIF uploads for govulncheck and Trivy only occur when the workflow is triggered by `schedule` or `workflow_dispatch` events, not on pull requests. Semgrep SARIF uploads can occur on any trigger when `upload-sarif: true`. This ensures scheduled security scans populate the GitHub Security Dashboard while PR checks remain fast and focused.

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

Refer to each workflow file for available inputs, secrets, and configuration options. When referencing workflows, it's recommended to use a specific version tag (e.g., `@v5.9.0`) rather than `@master` to ensure workflow stability.

## Release Management

This repository uses [release-please](https://github.com/googleapis/release-please) for automated releases. When pull requests are merged to the master branch:

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
