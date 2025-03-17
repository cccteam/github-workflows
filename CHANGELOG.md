# Changelog

## [5.4.0](https://github.com/cccteam/github-workflows/compare/v5.3.0...v5.4.0) (2025-03-17)


### Features

* Add monorepo support for all CI actions ([#53](https://github.com/cccteam/github-workflows/issues/53)) ([d1019ed](https://github.com/cccteam/github-workflows/commit/d1019ed4279ef9308fefc4fc8621f85538a25b27))

## [5.3.0](https://github.com/cccteam/github-workflows/compare/v5.2.0...v5.3.0) (2025-02-10)


### Features

* Add new branch type to Github Workflow check for Infrastructure changes ([590ec9f](https://github.com/cccteam/github-workflows/commit/590ec9f1e8a06dee19562b96cd26546a9cc4cee9))

## [5.2.0](https://github.com/cccteam/github-workflows/compare/v5.1.0...v5.2.0) (2024-09-06)


### Features

* Add Trunk Check Workflow Template for Terraform Repositories ([0a05667](https://github.com/cccteam/github-workflows/commit/0a05667421d06607a84b84aa95b6c12d9f2ae9df))

## [5.1.0](https://github.com/cccteam/github-workflows/compare/v5.0.0...v5.1.0) (2024-08-06)


### Features

* Add an optional 'golangci-lint-only-new-issues' input (default false) ([#42](https://github.com/cccteam/github-workflows/issues/42)) ([1722298](https://github.com/cccteam/github-workflows/commit/1722298732113220495eef910e48236467e5ff2e))

## [5.0.0](https://github.com/cccteam/github-workflows/compare/v4.1.0...v5.0.0) (2024-07-26)


### ⚠ BREAKING CHANGES

* fetch go version from go.mod instead of external go-version input

### Features

* fetch go version from go.mod instead of external go-version input ([4160e61](https://github.com/cccteam/github-workflows/commit/4160e61261edfa2bc7ee4f0e699c5e25cb78503c))

## [4.1.0](https://github.com/cccteam/github-workflows/compare/v4.0.0...v4.1.0) (2024-06-13)


### Features

* Optionally specify govulncheck version to use ([cc76a3d](https://github.com/cccteam/github-workflows/commit/cc76a3dec819fda64393f0a520c94676063070c9))


### Bug Fixes

* Conditions for security scan results reporting ([#36](https://github.com/cccteam/github-workflows/issues/36)) ([cc76a3d](https://github.com/cccteam/github-workflows/commit/cc76a3dec819fda64393f0a520c94676063070c9))
* Use latest stable Go version to install govulncheck ([cc76a3d](https://github.com/cccteam/github-workflows/commit/cc76a3dec819fda64393f0a520c94676063070c9))


### Code Refactoring

* Simplify use of Go version from go mod file ([cc76a3d](https://github.com/cccteam/github-workflows/commit/cc76a3dec819fda64393f0a520c94676063070c9))

## [4.0.0](https://github.com/cccteam/github-workflows/compare/v3.0.0...v4.0.0) (2024-06-12)


### ⚠ BREAKING CHANGES

* Removal of 'go-version' as an input to security-scan.yml causes a breaking change

### Bug Fixes

* Removal of 'go-version' as an input to security-scan.yml causes a breaking change ([b147c8c](https://github.com/cccteam/github-workflows/commit/b147c8cc4b609220bdf026113825de3353a6493d))
* Retrieve Go version from go mod file for govulncheck ([b147c8c](https://github.com/cccteam/github-workflows/commit/b147c8cc4b609220bdf026113825de3353a6493d))

## [3.0.0](https://github.com/cccteam/github-workflows/compare/v2.0.2...v3.0.0) (2024-05-10)


### ⚠ BREAKING CHANGES

* New required secret DEPENDABOT_ALERTS_TOKEN causes a breaking change ([#24](https://github.com/cccteam/github-workflows/issues/24))

### Features

* Add semantic pull request title workflow ([#26](https://github.com/cccteam/github-workflows/issues/26)) ([ef4ea81](https://github.com/cccteam/github-workflows/commit/ef4ea81b2b03c300b58b9170018dca31bdfb2c7f))
* New required secret DEPENDABOT_ALERTS_TOKEN causes a breaking change ([#24](https://github.com/cccteam/github-workflows/issues/24)) ([cafa49b](https://github.com/cccteam/github-workflows/commit/cafa49bb95a4adad6a5183f102e0c12a0f4a846e))
* Optionally scan the latest release & include Dependabot security alerts ([#24](https://github.com/cccteam/github-workflows/issues/24)) ([cafa49b](https://github.com/cccteam/github-workflows/commit/cafa49bb95a4adad6a5183f102e0c12a0f4a846e))

## [2.0.2](https://github.com/cccteam/github-workflows/compare/v2.0.1...v2.0.2) (2024-03-12)


### Bug Fixes

* Run go generate check from the proper directory ([#21](https://github.com/cccteam/github-workflows/issues/21)) ([71495dd](https://github.com/cccteam/github-workflows/commit/71495dd41dbb18721329c595fd6f53ea074c67fb))

## [2.0.1](https://github.com/cccteam/github-workflows/compare/v2.0.0...v2.0.1) (2024-02-26)


### Code Upgrade

* Upgrade linter to v1.56 ([#18](https://github.com/cccteam/github-workflows/issues/18)) ([7629ae1](https://github.com/cccteam/github-workflows/commit/7629ae16b7208a50a5c2b95bfd9454c4d42cbf76))

## [2.0.0](https://github.com/cccteam/github-workflows/compare/v1.1.0...v2.0.0) (2024-02-20)


### ⚠ BREAKING CHANGES

* Accept Slack channel ID as secret in golang-security-scan yml ([#16](https://github.com/cccteam/github-workflows/issues/16))

### Features

* Accept Slack channel ID as secret in golang-security-scan yml ([#16](https://github.com/cccteam/github-workflows/issues/16)) ([367894f](https://github.com/cccteam/github-workflows/commit/367894f218454c70ac9b23a5834f69cd64d0a6ce))
* Include scanner output in Issue body ([#13](https://github.com/cccteam/github-workflows/issues/13)) ([6b4613b](https://github.com/cccteam/github-workflows/commit/6b4613b174190dcd05641d00e6d49b459bc73fe9))

## [1.1.0](https://github.com/cccteam/github-workflows/compare/v1.0.1...v1.1.0) (2024-02-09)


### Features

* Add workflow for building and scanning a Docker image ([#14](https://github.com/cccteam/github-workflows/issues/14)) ([89e7e0a](https://github.com/cccteam/github-workflows/commit/89e7e0ada4970ca87320714651a33289dc65f8e9))

## [1.0.1](https://github.com/cccteam/github-workflows/compare/v1.0.0...v1.0.1) (2024-02-03)


### Bug Fixes

* Do not ignore unfixed in security scan ([#11](https://github.com/cccteam/github-workflows/issues/11)) ([141661b](https://github.com/cccteam/github-workflows/commit/141661bb9d1eb3adbfe406b8bf0ee6605baf9933))

## [1.0.0](https://github.com/cccteam/github-workflows/compare/v0.0.1...v1.0.0) (2024-01-30)


### Features

* Add support for golangci-lint timeout ([#7](https://github.com/cccteam/github-workflows/issues/7)) ([c882fce](https://github.com/cccteam/github-workflows/commit/c882fceee8143eb708275654ad02f4ac00228849))


### Bug Fixes

* Execute alert-related jobs even if trivyscan is skipped ([#6](https://github.com/cccteam/github-workflows/issues/6)) ([3b982e9](https://github.com/cccteam/github-workflows/commit/3b982e982ecad4ef1216d1cbed7e671598f04008))
