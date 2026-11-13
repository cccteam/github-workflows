# Vulnerability Autofix

[`vuln-autofix.yml`](../.github/workflows/vuln-autofix.yml) fixes dependency vulnerabilities that already have a published fix, without a person in the loop. Slack is told when a fix is merged, or when a fix needs a person. A run with nothing to fix ends silently.

## How it works

1. **Select.** The run collects open Dependabot alerts and, for Go, `govulncheck` findings. It keeps only those with a published fixed version (`first_patched_version` for Dependabot, `fixed_version` for govulncheck). A vulnerability without a published fix is never touched.
2. **Bump and check, one package at a time.** A script raises each package to its minimum fixed version: `go get` and `go mod tidy` for a Go module, a raised `go` directive for the Go standard library, `npm install` or `npm update` with `--package-lock-only --ignore-scripts` for npm. No model is involved. A package passes when:
   - the fix is not a major version change;
   - the fixed version is reached. For npm, every installed copy on the fixed version's major must reach it, and a copy on an older major counts as needing a major change;
   - for a raised `go` directive, no tracked Dockerfile builds with an older `golang:` image;
   - for Go, `govulncheck` runs (so the code compiles) and no longer reports the package.

   A package that passes becomes one commit. A package that does not pass is undone, so it cannot hold back the others.
3. **Pull requests.** The job token is read-only. A GitHub App token is created after the bumps and checks have finished, and it pushes the branches and opens the pull requests.
   - *Packages that passed:* branch `vuln-autofix`, one pull request, auto-merge (squash). Each later run replaces the branch and updates the same pull request.
   - *Packages left for a person:* branch `vuln-autofix-needs-human`, one **draft** pull request labelled `needs-human`, never auto-merged. It holds the passing bumps plus a first-pass bump of the packages that did not pass, and lists the reason for each. While that draft is open the workflow does not push to it, because a person may have pushed work to it.
4. **Slack.**
   - *A fix pull request is merged:* severity (critical and high are called out), the vulnerabilities with old and new versions, the link, and that it still needs a deployment. This also covers the draft once a person finishes and merges it.
   - *Packages are left for a person:* posted when the draft is opened. When their bump changed nothing there is no draft, and the message repeats on each run.
   - *Auto-merge is off or could not be enabled:* posted when the pull request is opened.
   - *The run failed:* one plain message with the run link, on each failed run.

Not reported: a fix pull request that is open with failing checks. It stays open until a person looks at it.

Supported: a Go module and/or an npm `package-lock.json` at the repository root. Other ecosystems, other lockfiles (bun, yarn, pnpm) and manifests in subdirectories are skipped silently. The plan is for Dependabot security updates to take over the alert-driven fixes, which leaves this workflow the govulncheck findings.

The run fails if the bumps changed any file other than `go.mod`, `go.sum`, `package.json` and `package-lock.json` at the repository root.

## Caller example

```yaml
name: Vulnerability Autofix
on:
  schedule:
    - cron: '17 6 * * *' # daily
  workflow_dispatch:
  pull_request:
    types: [closed] # tells Slack when a fix pull request is merged

jobs:
  vuln-autofix:
    # Replace the ref with the first release that contains this workflow
    uses: cccteam/github-workflows/.github/workflows/vuln-autofix.yml@v8.4.0
    permissions:
      contents: read
      pull-requests: read
    secrets:
      DEPENDABOT_ALERTS_TOKEN: ${{ secrets.DEPENDABOT_ALERTS_TOKEN }}
      AUTOFIX_APP_CLIENT_ID: ${{ secrets.AUTOFIX_APP_CLIENT_ID }}
      AUTOFIX_APP_PEM: ${{ secrets.AUTOFIX_APP_PEM }}
      SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}
      SLACK_CHANNEL_ID: ${{ secrets.SLACK_CHANNEL_ID }}
```

The inputs (`auto-merge`, `go-private`, `govulncheck-version`, `slack-channel-id`, `runs-on`) are described in the workflow file.

## Setup prerequisites

- **`DEPENDABOT_ALERTS_TOKEN`**: the same secret `golang-security-scan` uses. `GITHUB_TOKEN` cannot read Dependabot alerts.
- **`AUTOFIX_APP_CLIENT_ID`** and **`AUTOFIX_APP_PEM`**: client ID and private key of a GitHub App installed on the repository with Contents and Pull requests write access. An app is required because a pull request opened with `GITHUB_TOKEN` does not trigger workflows, so its checks would never run.
- **`GO_PRIVATE_MODULES_TOKEN`** with the `go-private` input, only for repositories that depend on private Go modules: a read-only token that can clone those modules.
- **`SLACK_BOT_TOKEN`** and **`SLACK_CHANNEL_ID`**: as for `golang-security-scan`.
- **Branch protection. These are mandatory, because auto-merge is the only gate before the merge:**
  - "Allow auto-merge" and squash merging are enabled on the repository.
  - The base branch has **required status checks** that build and test the code. Without required checks, auto-merge merges at once.
  - The bot cannot approve its own pull request. Either the branch does not require a review for these pull requests, or the GitHub App is a bypass actor of a ruleset that holds only the review rule. A bypass applies to every rule in its ruleset, so the required checks must be in a different ruleset.
  - Checks that a bot pull request cannot pass (for example a closes-an-issue check) are excluded for it.
- **Permissions**: the calling job must grant the permissions shown above, because a reusable workflow cannot exceed its caller.
- **Across organizations**: a private repository's reusable workflows can be called only from repositories in the same organization. Repositories in another organization, for example AscendiumApps, need a copy of the workflow.

## Tests

`tests/vuln-autofix/run.sh` runs the workflow's own step scripts against fixtures and small git repositories, with fake `go`, `npm`, `govulncheck`, `gh` and `curl` commands. It needs bash, git, jq and python3 with PyYAML. No workflow runs it.
