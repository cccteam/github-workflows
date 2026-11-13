# GitHub Workflows

This repository provides a collection of reusable GitHub Actions workflow templates for use across Cloud Computing Consultants (CCC) projects. The workflows are located in the [`.github/workflows`](.github/workflows) directory.

## Available Workflows

### Angular Workflows

- **Angular CI**
  [`angular-ci.yml`](.github/workflows/angular-ci.yml):
  Runs configurable bun scripts for all Angular projects defined in angular.json. Supports any bun script names defined in package.json with defaults of build and lint.

### Go Workflows

- **Golang CI Workflow**
  [`golang-ci.yml`](.github/workflows/golang-ci.yml):
  Runs Go tests, builds, lints, and vulnerability checks for Go projects. In a repository with several Go modules (the packages of `release-please-config.json`), only the modules the pull request changed are checked, in series inside one job per check, so the check names never carry a module. See [Golang CI required checks](#golang-ci-required-checks).

- **Golang Security Scan**
  [`golang-security-scan.yml`](.github/workflows/golang-security-scan.yml):
  Performs comprehensive security scanning for Go projects using govulncheck, Grype, Semgrep, and Dependabot alerts. Notifies via Slack and creates GitHub issues for failed jobs. Semgrep here scans the whole repository with no baseline (the pull request scan in golang-ci is the gate; this is the inventory) and its findings open or update a "Semgrep Report" issue like the other scanners'. Optionally uploads SARIF reports to GitHub Advanced Security Dashboard for scheduled and manual runs.

### Docker Workflows

- **Docker Build & Scan**
  [`docker-build-and-scan.yml`](.github/workflows/docker-build-and-scan.yml):
  Lints Dockerfiles, builds Docker images, and scans them for vulnerabilities using Grype.

### Terraform Workflows

- **Terraform CI**
  [`terraform-ci.yml`](.github/workflows/terraform-ci.yml):
  Comprehensive Terraform CI workflow that auto-formats files with OpenTofu (and pushes changes back to the PR), generates documentation for modules, runs linting, and performs security scanning. Includes TFLint and Checkov scans optimized for changed files only, and reports when a component's environment folders hold different code (see [Environment consistency](#environment-consistency)). That report only warns for now. Optionally uploads SARIF results to GitHub Advanced Security Dashboard.

- **Terraform Security Scan**
  [`terraform-security-scan.yml`](.github/workflows/terraform-security-scan.yml):
  Continuously scans the entire Terraform codebase on a weekly schedule (or manually triggered).

  
### PR Quality & Security Workflows

- **Semantic Pull Request Title**
  [`semantic-pull-request-title.yml`](.github/workflows/semantic-pull-request-title.yml):
  Enforces semantic PR titles following the [Conventional Commits](https://www.conventionalcommits.org/) format.

- **Closes Issue Check**
  [`closes-issue-check.yml`](.github/workflows/closes-issue-check.yml):
  Ensures pull requests reference and close at least one issue.

- **Secret Scanning**
  [`secrets-scanning.yml`](.github/workflows/secrets-scanning.yml):
  Performs secret scanning on the repository using TruffleHog to detect verified and unknown secrets. Supports SARIF upload to GitHub Security.

### Release Workflows

- **Release Please**
  [`release-please.yml`](.github/workflows/release-please.yml):
  Automates versioning and releasing using release-please with GitHub App authentication for enhanced security.

## Usage

To use a reusable workflow in your repository, create a workflow file in your `.github/workflows` directory that references one of the workflows in this repository using the `workflow_call` event.

### Basic Usage Example

```yaml
name: CI
on:
  pull_request:
  push:
    branches: [master] # the default branch: see Caches below

jobs:
  golang-ci:
    uses: cccteam/github-workflows/.github/workflows/golang-ci.yml@v8.2.0
    with:
      build-tags: '["", "dev"]'
      golangci-lint-version: 'v2.12.2'
```

#### Golang CI caches

Each Go job restores the build cache (the linter its analysis cache with it) from the nearest saved entry of its own lineage, keyed by the changed modules' go.sum files and the commit, so a run compiles only what the commit changed. GitHub serves a pull request only the entries saved on its own branch and on its base branch, which is why the calling workflow runs on `push` to the default branch too: that run checks every module (it is the merge result) and saves an entry after every job, and the next pull request starts from it. A pull request run saves only when it restored nothing (a repository whose base branch doesn't run this workflow, or a cold one), so its later pushes start warm. A pull request that changes dependencies restores the nearest base branch entry and doesn't save: its entries would be bigger than the base branch's, and a few of them evict the base branch's entries within minutes. The module cache is not cached: the module proxy serves it in seconds, and at about half of every entry it would push the base branch's entries out of the repository's 10 GB cache limit.

The tools are pinned by inputs with current defaults: `govulncheck-version` (run from the module cache), `mockgen-version`, `semgrep-image` (by digest); the vulnerability database and the Semgrep rules are read live. `coverage: true` makes the untagged test leg measure statement coverage and write a per-package table to the job summary (`coverage-exclude` is a regular expression over file paths left out, generated mocks say), which replaces a separate coverage job. `runs-on-heavy` names a runner for the test and lint jobs alone, so a larger runner carries the compiles while the cheap jobs stay on the standard one.

#### Golang CI required checks

The workflow lists the Go modules the pull request changed (`detect-modules`, diffing against the pull request's base branch, or the branch the `base-branch` input names), then runs each check once per workflow run, looping over the changed modules in series. Every module runs even when an earlier one failed, and the job fails at the end naming each failed module. An unchanged module takes no runner, and when nothing changed the checks after `detect-modules` are skipped and report success.

Because the check names never carry a module, a ruleset requires the same names however many modules the repository holds. With the job id `golang-ci` and the build tags above, require:

- `golang-ci / detect-modules`
- `golang-ci / Check for go generate changes`
- `golang-ci / Run tests and builds`
- `golang-ci / Run tests and builds (dev)`
- `golang-ci / Go Vulnerability Check`
- `golang-ci / Run Semgrep Scan`
- `golang-ci / Run golangci-lint`
- `golang-ci / Run golangci-lint (dev)`

`detect-modules` must be among them: a job skipped by its condition counts as a success for a required check, and the dependents of a failed job are skipped, so a failed detection would otherwise let a pull request through unchecked.

Before v8.0.0 the checks were one job per module (`Run tests and builds (./pkg)`, `Run golangci-lint (dev, ./pkg)`, ...), every module's job ran on every pull request, and a ruleset had to name each module's jobs. Moving to v8.0.0 means replacing those names in the ruleset with the list above.

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
      bun-version: '1.3.13'
      working-directory: './frontend'

  # Run custom bun scripts
  angular-full-check:
    uses: cccteam/github-workflows/.github/workflows/angular-ci.yml@v5.9.0
    with:
      bun-version: '1.3.13'
      working-directory: './frontend'
      commands: '["build", "lint", "test", "audit", "format:check"]'

  # Run only specific checks
  angular-build-only:
    uses: cccteam/github-workflows/.github/workflows/angular-ci.yml@v5.9.0
    with:
      commands: '["build"]'
```

#### Common Angular Bun Scripts

The Angular CI workflow can run any bun script defined in your `package.json`. Common examples include:

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
    - cron: '0 2 * * *' # Daily at 2 AM UTC
  workflow_dispatch:

jobs:
  security-scan:
    uses: cccteam/github-workflows/.github/workflows/golang-security-scan.yml@v5.9.0
    with:
      upload-sarif: true
      execute-grype-scan: true
      execute-dependabot-check: true
      execute-semgrep-scan: true
      semgrep-config: auto
    secrets:
      SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}
      SLACK_CHANNEL_ID: ${{ secrets.SLACK_CHANNEL_ID }}
      DEPENDABOT_ALERTS_TOKEN: ${{ secrets.DEPENDABOT_ALERTS_TOKEN }}
```

**Note:** SARIF uploads occur whenever `upload-sarif: true` is set.

### Terraform CI Example

```yaml
name: Infrastructure Checks
on:
  pull_request:

permissions: {}

jobs:
  terraform-ci:
    uses: cccteam/github-workflows/.github/workflows/terraform-ci.yml@<sha> # <version>
    with:
      tofu_version: '1.13.9' # Optional: the OpenTofu version tofu fmt runs at
      upload_sarif: false    # Optional: Upload security results to GitHub Security
    secrets:
      app_client_id: ${{ secrets.TERRAFORM_APP_CLIENT_ID }}
      app_pem: ${{ secrets.TERRAFORM_APP_PEM }}
    permissions:
      actions: read
      contents: write
      pull-requests: write
      security-events: write
```

Changed files are formatted with `tofu fmt` at `tofu_version`. The `terraform_version` input is deprecated and ignored: a call that still passes it gets a warning, and a future major release will remove it. The `working_dirs` input is gone. Changed directories are detected from the pull request.

Docs are generated only for modules. A changed directory with a `backend` or `cloud` block is a root configuration, and the docs step skips it. This also keeps terraform-docs away from OpenTofu-only syntax such as provider `for_each`, which it can't parse ([terraform-docs#895](https://github.com/terraform-docs/terraform-docs/issues/895)).

**Note:** When `upload_sarif: true` is set, SARIF output is automatically enabled for both TFLint and Checkov regardless of the `output_format` and `output_file_path` inputs.

#### Environment consistency

Each component keeps one root folder per environment, numbered in promotion order, and every folder must hold the same code. Values that differ between environments come from Scalr workspace variables. A resource only some environments need goes behind a variable that turns it on, such as `count = var.enable_cloud_sql ? 1 : 0`.

The `environment-consistency` job finds every folder named `<number>-<code>`, where the code is one of `environment_codes`, and groups the folders by parent directory. It compares each folder with the one before it in promotion order (`1-dev` with `2-tst`, `2-tst` with `4-prd`), so each difference shows up at the step where it starts. Only OpenTofu files are compared (`environment_include_files`: `*.tf`, `*.tf.json` and `.terraform.lock.hcl`), at any depth. A file in one folder and not the other fails the check, and so does any line that differs, except for these:

- Quoted values inside the `cloud` or `backend` block of the `terraform` block, and inside `data "scalr_outputs"` blocks, are masked in every file. These hold the Scalr workspace, organization and environment. The block header is still compared, so switching one environment to a different backend type shows up. Values outside those blocks are compared, so an `environment` tag must come from a variable (`environment = var.environment`), not a quoted name.
- `import`, `moved` and `removed` blocks, and the comment lines directly above them, are skipped in every file. Import IDs differ per environment, and the blocks are deleted once every environment has applied them. A file left with nothing else in it, such as an `import.tf`, counts as absent.
- Blank lines are skipped. Every other comment is compared like code, so a comment that names one environment fails the check.
- Files matching `environment_ignore_files` are skipped. It's empty by default.

The lock file is compared like any other file, so every environment runs the provider versions the environment before it tested.

Numbered folders with other codes, such as `0-bootstrap`, `3-shr` or `4-cmn`, are left out, so layered repos and shared-services folders don't fail the check. The job summary lists them, so a non-standard name such as `3-prod` doesn't drop out of the check unnoticed. A component with only one environment folder is skipped, and a module repository, which has no environment folders, passes with nothing to compare.

The check covers the whole repository on every run, not only the folders a pull request changed, so drift that is already on the default branch shows up on every pull request.

`environment_consistency` sets what happens when the folders differ:

- `warn` (the default): the job adds a warning annotation for each difference, writes the diffs to the job summary, comments on the pull request, and passes.
- `fail`: the same, but the job fails. A repository whose folders match should set this, so new drift can't get in.
- `off`: the job doesn't run.

The pull request comment lists the files that differ (the first 50) and links to the job summary for the diffs. The job keeps one comment per pull request and edits it on each run, and when the folders match again it rewrites the comment to say so. A pull request from a fork gets a read-only token, so it gets no comment, and the job doesn't fail over that. The job needs `pull-requests: write`, which callers already grant for `terraform-docs`.

`warn` is the default while repositories clean up. A future major release will make `fail` the default, and the comment tells each pull request so.

| Input | Default | Description |
| --- | --- | --- |
| `environment_consistency` | `warn` | `warn`, `fail` or `off` |
| `environment_working_directory` | `.` | Directory to search |
| `environment_codes` | `dev,int,tst,uat,stg,prd` | Environment codes whose folders are compared |
| `environment_include_files` | `*.tf,*.tf.json,.terraform.lock.hcl` | Comma-separated glob patterns, matched against file names, of the files compared |
| `environment_ignore_files` | | Comma-separated glob patterns, matched against file names, left out |

### Terraform Security Scan Example

```yaml
name: Terraform Security Scan
on:
  schedule:
    - cron: '0 0 * * 1' # Weekly on Monday at midnight UTC
  workflow_dispatch:

jobs:
  security-scan:
    uses: cccteam/github-workflows/.github/workflows/terraform-security-scan.yml@v5.9.0
```

Results are always uploaded to GitHub Advanced Security Dashboard. No secrets are required — the workflow uses the built-in `GITHUB_TOKEN` via `security-events: write` permission.

**Note:** For most use cases, the comprehensive [`terraform-ci.yml`](#terraform-ci-example) workflow is recommended for PR checks, while [`terraform-security-scan.yml`](#terraform-security-scan-example) handles continuous full-repository scanning on a schedule.

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

### Setting up GitHub App Authentication

For enhanced security and permissions, release-please can be configured to use GitHub App authentication instead of personal access tokens. This provides short-lived tokens with scoped permissions.

1. Navigate to the appropriate level and create a GitHub App:
   - For GitHub Enterprise Cloud: Go to your enterprise account > Settings > Developer settings > GitHub Apps > New GitHub App
   - For an organization: Go to your organization > Settings > Developer settings > GitHub Apps > New GitHub App

   Then configure the GitHub App with the following settings:

   - **GitHub App name:** Choose a descriptive name (e.g., "Release Please Bot")
   - **Homepage URL:** Set to any valid URL (e.g., your repository or organization URL)
   - **Repository permissions:**
     - Contents: Read and write
     - Metadata: Read (included by default)
     - Pull requests: Read and write
     - Workflows: Read and write
   - **Organization permissions:** Ensure set to none
   - **Account permissions:** Ensure set to none
   - **Enterprise permissions:** Ensure set to none

   **Note:** After creating the GitHub App, take note of the App ID displayed on the app's settings page - this will be used for the `RELEASE_PLEASE_APP_ID` secret.

2. Install the app on the organizations or repositories within your enterprise (or organization) where release-please needs access.

3. Generate a private key for the app and store it as an organization secret (recommended for multi-repo setups) or repository secret named `RELEASE_PLEASE_APP_PEM`.
   **Note:** For security, do not store the private key elsewhere (e.g., password managers). If the key is compromised, rotate it through the GitHub App settings and replace the value stored in your actions secrets.

4. Store the app ID as a repository secret named `RELEASE_PLEASE_APP_ID`.
   **Note:** If the app is created at the enterprise level, ensure you use the enterprise app ID, not an organization-level app ID.

5. Update your release-please workflow to include GitHub App token generation. It should look something like this sample workflow:

```yaml
- name: Generate GitHub App Token
  uses: actions/create-github-app-token@v2
  id: app-token
  with:
    app-id: ${{ secrets.RELEASE_PLEASE_APP_ID }}
    private-key: ${{ secrets.RELEASE_PLEASE_APP_PEM }}

- name: Run Release Please
  uses: googleapis/release-please-action@v4
  with:
    token: ${{ steps.app-token.outputs.token }}
    config-file: release-please-config.json
    manifest-file: .release-please-manifest.json
```

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
