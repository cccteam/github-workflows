# Changelog

## [5.13.1](https://github.com/cccteam/github-workflows/compare/v5.13.0...v5.13.1) (2025-11-14)


### Bug Fixes

* checkov ignores ([#103](https://github.com/cccteam/github-workflows/issues/103)) ([ab5f235](https://github.com/cccteam/github-workflows/commit/ab5f235214ce50fd2807c9fb826e389be4f183a9))

## [5.13.0](https://github.com/cccteam/github-workflows/compare/v5.12.4...v5.13.0) (2025-11-12)


### Features

* Build all go packages in the working dir and below ([#100](https://github.com/cccteam/github-workflows/issues/100)) ([86239fd](https://github.com/cccteam/github-workflows/commit/86239fdf53d7bba3f765dc127f97c61de702439f))

## [5.12.4](https://github.com/cccteam/github-workflows/compare/v5.12.3...v5.12.4) (2025-09-04)


### Code Refactoring

* Skip doing the work when no changes detected in a module instead of not running the action. ([#94](https://github.com/cccteam/github-workflows/issues/94)) ([b6b59e3](https://github.com/cccteam/github-workflows/commit/b6b59e3c52d5f09b67c25ec7626dff1f7d347902))

## [5.12.3](https://github.com/cccteam/github-workflows/compare/v5.12.2...v5.12.3) (2025-08-22)


### Bug Fixes

* Add runner configuration option to Angular CI ([#91](https://github.com/cccteam/github-workflows/issues/91)) ([34b1685](https://github.com/cccteam/github-workflows/commit/34b168568b0dfbd30d1785849e60bf372ff7d3c0))

## [5.12.2](https://github.com/cccteam/github-workflows/compare/v5.12.1...v5.12.2) (2025-08-22)


### Bug Fixes

* Fix detect-modules for situation where no release-please config exists ([#89](https://github.com/cccteam/github-workflows/issues/89)) ([ea7dc08](https://github.com/cccteam/github-workflows/commit/ea7dc08cb4ded3b6976dd2a560cf4202ea94d9ce))


### Code Upgrade

* **deps:** Bump the github-actions group across 1 directory with 9 updates ([#88](https://github.com/cccteam/github-workflows/issues/88)) ([adf9936](https://github.com/cccteam/github-workflows/commit/adf993665b91abc75101de22b1a2c5e29c5c0065))
* golangci-lint will now need to be upgraded to 2.0+ ([#88](https://github.com/cccteam/github-workflows/issues/88)) ([adf9936](https://github.com/cccteam/github-workflows/commit/adf993665b91abc75101de22b1a2c5e29c5c0065))

## [5.12.1](https://github.com/cccteam/github-workflows/compare/v5.12.0...v5.12.1) (2025-08-11)


### Documentation

* Fix ' in commands description in Angular CI workflow ([#86](https://github.com/cccteam/github-workflows/issues/86)) ([e61ba6e](https://github.com/cccteam/github-workflows/commit/e61ba6e77e7cf98fb4af692bbe842b24990eef5c))

## [5.12.0](https://github.com/cccteam/github-workflows/compare/v5.11.0...v5.12.0) (2025-08-11)


### Features

* **workflow:** Add Angular Check workflow for project checks ([#84](https://github.com/cccteam/github-workflows/issues/84)) ([ccc2cb9](https://github.com/cccteam/github-workflows/commit/ccc2cb9450cc358404825f6983333fc09f94ef32))

## [5.11.0](https://github.com/cccteam/github-workflows/compare/v5.10.0...v5.11.0) (2025-07-23)


### Features

* Support config as a semantic PR title type ([#80](https://github.com/cccteam/github-workflows/issues/80)) ([663a3f0](https://github.com/cccteam/github-workflows/commit/663a3f0bb0081a9ac1c1244201b56ac2004bb0fe))

## [5.10.0](https://github.com/cccteam/github-workflows/compare/v5.9.0...v5.10.0) (2025-06-23)


### Features

* Update README to enhance workflow organization and clarity ([#77](https://github.com/cccteam/github-workflows/issues/77)) ([699a6a6](https://github.com/cccteam/github-workflows/commit/699a6a6bcddc5e55ed891de751e861052b48fe75))

## [5.9.0](https://github.com/cccteam/github-workflows/compare/v5.8.0...v5.9.0) (2025-06-16)


### Features

* Add reusable secret scanning workflow with TruffleHog ([#74](https://github.com/cccteam/github-workflows/issues/74)) ([0f0abbb](https://github.com/cccteam/github-workflows/commit/0f0abbb193ab0e9385c96ed5af1d25d5c3492d0a))

## [5.8.0](https://github.com/cccteam/github-workflows/compare/v5.7.0...v5.8.0) (2025-06-16)


### Features

* **workflows:** Add Checkov and TFLint for Terraform code scanning ([#72](https://github.com/cccteam/github-workflows/issues/72)) ([b367b9a](https://github.com/cccteam/github-workflows/commit/b367b9a55b9ff7e5ba49401ad98df683fb1f0033))

## [5.7.0](https://github.com/cccteam/github-workflows/compare/v5.6.1...v5.7.0) (2025-06-13)


### Features

* Add Terraform format check and Trivy scan workflows ([#70](https://github.com/cccteam/github-workflows/issues/70)) ([f13cf73](https://github.com/cccteam/github-workflows/commit/f13cf7396a9b92b9394f088a6fdd9bf8eb75b8dc))

## [5.6.1](https://github.com/cccteam/github-workflows/compare/v5.6.0...v5.6.1) (2025-05-29)


### Bug Fixes

* Add missing -f flag in docker build ([#68](https://github.com/cccteam/github-workflows/issues/68)) ([cc62d16](https://github.com/cccteam/github-workflows/commit/cc62d16536d199cd63d2740a17a110b46732e128))

## [5.6.0](https://github.com/cccteam/github-workflows/compare/v5.5.1...v5.6.0) (2025-05-14)


### Features

* Add runs-on input for CI reusable workflow ([#65](https://github.com/cccteam/github-workflows/issues/65)) ([4b8a71c](https://github.com/cccteam/github-workflows/commit/4b8a71c48ef516479ea070ffdc013678255c18e1))
* Add runs-on input for Docker and security scan reusable workflow ([#67](https://github.com/cccteam/github-workflows/issues/67)) ([ca01f2d](https://github.com/cccteam/github-workflows/commit/ca01f2d33668c1119a80b04b504eb3137e936999))

## [5.5.1](https://github.com/cccteam/github-workflows/compare/v5.5.0...v5.5.1) (2025-03-25)


### Bug Fixes

* update token reference ([#62](https://github.com/cccteam/github-workflows/issues/62)) ([c689c56](https://github.com/cccteam/github-workflows/commit/c689c565eecd183cb785b35521359cd7e5f788f6))

## [5.5.0](https://github.com/cccteam/github-workflows/compare/v5.4.1...v5.5.0) (2025-03-25)


### Features

* terraform-docs + trunk auto-upgrade workflow additions ([#60](https://github.com/cccteam/github-workflows/issues/60)) ([b0b4d46](https://github.com/cccteam/github-workflows/commit/b0b4d4614ebfbc5d36812cc8d68be9342fa35d19))

## [5.4.1](https://github.com/cccteam/github-workflows/compare/v5.4.0...v5.4.1) (2025-03-19)


### Code Upgrade

* Update the security scan for changes to aquasecurity/trivy-action ([#57](https://github.com/cccteam/github-workflows/issues/57)) ([4cf5933](https://github.com/cccteam/github-workflows/commit/4cf5933354890e6534ab4468f4a58c7fc104bbbb))

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
