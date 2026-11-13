# Vulnerability Autofix

[`vuln-autofix.yml`](../.github/workflows/vuln-autofix.yml) fixes dependency vulnerabilities that already have a published fix, without a person in the loop. A person is told only after action was taken (a pull request was opened or merged, including a draft first-pass fix that needs more work). A run with nothing actionable ends silently.

## How it works

1. **Gate (no LLM).** Collects open Dependabot alerts and, for Go, `govulncheck` findings. A vulnerability is actionable only when a fixed version is published (`first_patched_version` for Dependabot, `fixed_version` for govulncheck; a Go standard library finding is fixed by raising the `go` directive). Anything without a published fix is never touched. If nothing is actionable, the run ends here.
2. **Dedupe.** If an open `claude/vuln-autofix/*` pull request already carries the same fix, or an open issue records that the same set of vulnerabilities could not be fixed (both matched by a marker in the body), the run ends. If that open pull request is not a draft and has failed checks, it will not merge by itself: the run labels it `needs-human`, comments on it and posts to Slack, once.
3. **Fix.** [`anthropics/claude-code-action`](https://github.com/anthropics/claude-code-action) runs on a new branch `claude/vuln-autofix/<date>-<run id>` with a short tool allow-list (read-only file tools, `go get/mod/list`, `npm update/install/ls`, read-only git). Its prompt names only the packages and their minimum fixed versions. While it runs, the job token is read-only, the GitHub App token does not exist yet, and npm package install scripts are turned off.
4. **Guards (deterministic).** The result is checked for:
   - only `go.mod`, `go.sum`, `go.work`, `go.work.sum`, `package.json` and `package-lock.json` changed (plus anything matching `extra-allowed-files-regex`). Changes under `.github/` are always reverted and never pushed, and a new file that is not one of these (for example a binary written by `go build`) is left out of the commit;
   - `go.mod` gained no `replace`, `exclude` or `retract`, and `package.json` changed only its dependency sections;
   - no dependency changed major version;
   - the fixed versions are reached, the code still builds (`go build ./...`, `npm ci` and `npm run build --if-present`), and a fresh `govulncheck` run reports no fixable vulnerability. Tests run in the pull request's own CI.
   - when the `go` directive was raised, no tracked Dockerfile builds with an older `golang:` image tag. Dockerfiles are not changed by the workflow, so this makes the pull request a draft for a human to finish.
5. **Pull request.**
   - *All guards pass:* a ready pull request with labels, severity, advisory IDs, old to new versions and side effects. With `auto-merge: true` it runs `gh pr merge --auto --squash`, so it merges only when the required checks pass.
   - *A guard fails:* the first-pass fix is kept, pushed, and opened as a **draft** pull request labelled `needs-human` (`needs-human-label`). Its body lists exactly which guards failed and what remains. Auto-merge is never enabled for it.
   - *The bump produced no change at all:* no pull request. An issue labelled `needs-human` is opened with the reason, and Slack says a fix exists but needs a human. While that issue is open the same set of vulnerabilities is not tried or reported again; close it to let the next run try again.
6. **Slack.** One message, only after action. Critical and high severity are called out at the top. It carries the vulnerabilities, how they were addressed, the PR link, the merge status, "needs deployment to reach production" and any side effects (a changed `go` directive or toolchain, indirect dependencies). For a draft first-pass fix it says more work is needed and why. An unexpected workflow failure posts once and opens an issue; later failed runs are not posted while that issue is open, and the first run that does not fail closes it.

Supported: a Go module and/or an npm `package-lock.json` at the repository root. Other ecosystems, other lockfiles (bun, yarn, pnpm) and manifests in subdirectories are ignored for now: a Dependabot alert whose manifest is not at the repository root is skipped, so the run stays silent for it.

## Caller example

```yaml
name: Vulnerability Autofix
on:
  schedule:
    - cron: '17 6 * * *' # daily
  workflow_dispatch:

jobs:
  vuln-autofix:
    # Replace the ref with the first release that contains this workflow
    uses: cccteam/github-workflows/.github/workflows/vuln-autofix.yml@v8.4.0
    permissions:
      contents: read
      pull-requests: read
      issues: read
    with:
      auto-merge: true
    secrets:
      DEPENDABOT_ALERTS_TOKEN: ${{ secrets.DEPENDABOT_ALERTS_TOKEN }}
      AUTOFIX_APP_CLIENT_ID: ${{ secrets.AUTOFIX_APP_CLIENT_ID }}
      AUTOFIX_APP_PEM: ${{ secrets.AUTOFIX_APP_PEM }}
      ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }} # or CLAUDE_CODE_OAUTH_TOKEN
      SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}
      SLACK_CHANNEL_ID: ${{ secrets.SLACK_CHANNEL_ID }}
```

Do not give the calling workflow a `concurrency` group named `vuln-autofix-<repo>`: the reusable workflow already uses that name, and the same name in both makes the run cancel itself.

## Inputs

| Input | Default | Purpose |
| --- | --- | --- |
| `auto-merge` | `true` | Enable auto-merge (squash) on the pull request. |
| `pr-labels` | `dependencies,security` | Labels for the pull request, created if missing. |
| `needs-human-label` | `needs-human` | Label on the draft pull request opened when a guard failed, and on the issue opened when no pull request could be opened. |
| `extra-allowed-files-regex` | empty | Extra file paths the fix may change, for example `^\.go-version$`. |
| `go-private` | empty | `GOPRIVATE` value for private Go modules, for example `github.com/my-org/*`. Needs `GO_PRIVATE_MODULES_TOKEN`. |
| `govulncheck-version` | `v1.9.0` | govulncheck release to install. |
| `node-version` | `lts/*` | Node version for npm builds. |
| `slack-channel-id` | empty | Overrides `SLACK_CHANNEL_ID`. |
| `runs-on` | `ubuntu-latest` | Runner. |

## Setup prerequisites

- **`DEPENDABOT_ALERTS_TOKEN`**: the same secret `golang-security-scan` uses. `GITHUB_TOKEN` cannot read Dependabot alerts, so a PAT or GitHub App token with that read access is required.
- **`AUTOFIX_APP_CLIENT_ID`** and **`AUTOFIX_APP_PEM`**: client ID and private key of a GitHub App installed on the repository with Contents, Pull requests and Issues write access. The workflow creates a short-lived token from them after the Claude step has finished, and uses it to push the branch, open the pull request, enable auto-merge and open issues. The job's own `GITHUB_TOKEN` is read-only, so no token that can write exists while Claude runs. An app is required because pull requests opened with `GITHUB_TOKEN` do not trigger workflows, so their checks would never run.
- **`GO_PRIVATE_MODULES_TOKEN`** with the `go-private` input (only for repositories that depend on private Go modules): a read-only token that can clone those modules. It is available to the Claude step, so it must not have write access.
- **`ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN`**: credential for Claude.
- **`SLACK_BOT_TOKEN`** and **`SLACK_CHANNEL_ID`**: as for `golang-security-scan`.
- **Auto-merge and branch protection**: enable "Allow auto-merge" on the repository. The bot cannot approve its own pull request, so the protected branch must either not require a human review for these pull requests or add the GitHub App as a bypass actor for that rule in a ruleset. Checks that cannot pass on a bot PR (for example a closes-an-issue check) must be excluded for it. If auto-merge cannot be enabled, the PR stays open and Slack says a human needs to merge it.
- **Permissions**: the calling job must grant the permissions shown above, because a reusable workflow cannot exceed its caller.
- **Across organizations**: a private repository's reusable workflows can be called only from repositories in the same organization (and only when its Actions access setting allows it). Repositories in another organization, for example AscendiumApps, need a copy of the workflow in their own organization, or this repository must allow access under its Settings > Actions > General > Access.

## Tests

`tests/vuln-autofix/run.sh` runs the workflow's own gate, guard, pull request, issue and failed-checks scripts against fixtures: an unfixed alert is skipped, a fixed alert is selected, and and a non-dependency file, a major bump, a `replace` directive or a `package.json` scripts change in the diff is flagged while the diff is kept. With a fake `gh` it also checks that a clean fix opens a ready PR with auto-merge, and a failed guard opens a draft labelled `needs-human` with no auto-merge call. Run it with bash, git, jq and python3 with PyYAML.
