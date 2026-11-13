# GitHub Workflows

Reusable GitHub Actions workflows for Cloud Computing Consultants (CCC) projects. Each file in [`.github/workflows`](.github/workflows) that has a `workflow_call` trigger is one reusable workflow.

## Finding out what a workflow does

Read the workflow file at the version you pin. Each input and secret has a description, and the larger workflows open with a comment that explains how they behave. The jobs' `permissions` blocks list what your calling job must grant.

[CHANGELOG.md](CHANGELOG.md) lists what changed in each release.

## Calling a workflow

```yaml
name: CI
on:
  pull_request:

permissions: {}

jobs:
  ci:
    uses: cccteam/github-workflows/.github/workflows/<workflow>.yml@<commit-sha> # vX.Y.Z
    with:
      some_input: value
    secrets:
      some_secret: ${{ secrets.SOME_SECRET }}
    permissions:
      contents: read
```

- Pin the full commit SHA of a [release](https://github.com/cccteam/github-workflows/releases), with the tag in a comment. A tag can be moved, and a SHA can't. Renovate updates both in repositories that use it.
- Set `permissions: {}` at the top of the file, and grant each job the permissions the called workflow's jobs request. GitHub won't start a called job that asks for more than the caller grants.
- Pass each secret by name instead of `secrets: inherit`, so a workflow only gets the secrets it lists.

## GitHub App secrets

A workflow that pushes commits or opens pull requests authenticates as a GitHub App, not with `GITHUB_TOKEN`. Events caused by `GITHUB_TOKEN` don't trigger other workflows, so a commit or pull request it creates would skip CI.

These workflows take the App's client ID and a private key as secrets. The inputs that take an App ID instead are deprecated. To set one up:

1. In the organization's settings, open Developer settings > GitHub Apps and create an App with the repository permissions the workflow needs. Leave organization and account permissions at none.
2. Install the App on the repositories that call the workflow.
3. Generate a private key, and store the client ID and the key as organization secrets. Don't keep a copy of the key anywhere else. If it leaks, generate a new one and replace the secret.

## Releases and versioning

[release-please](https://github.com/googleapis/release-please) cuts releases from [Conventional Commits](https://www.conventionalcommits.org/) on `master`. Pull requests are squash merged, so the pull request title becomes the commit message:

- `fix:` releases a patch version and `feat:` a minor version.
- A breaking change (`feat!:`, or a `BREAKING CHANGE:` footer) releases a major version.

A change breaks callers if it removes or renames an input or secret, makes one required, or makes a job request a permission callers don't grant yet. To remove an input, deprecate it first. Keep accepting it, ignore it or map it to its replacement, print a warning, and say in its description which major release will drop it.

## Contributing

- Give a new workflow a `workflow_call` trigger, and name the file after what it checks or builds.
- Describe every input and secret.
- Set `permissions: {}` at the top and grant each job only what it needs.
- Pin every action to a full commit SHA with the version in a comment.
- Use a Conventional Commit title for the pull request.

Adding or changing a workflow doesn't need a README change.

## License

See [LICENSE](LICENSE).
