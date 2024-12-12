# Guide: Semantic release

- [Guide: Semantic release](#guide-semantic-release)
  - [Overview](#overview)
  - [Key files](#key-files)
  - [Configuration checklist](#configuration-checklist)
  - [Testing](#testing)

## Overview

Semantic release ([semantic-release](https://semantic-release.gitbook.io/semantic-release)) is used for automatically tagging and creating GitHub releases with change logs from commit messages. It uses the [SemVer](https://semver.org/) convention and the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification by describing the features, fixes, and breaking changes made in commit messages.

The table below shows which commit message gets you which release type when semantic-release runs (using the default configuration):

| Commit message | Release type |
|----------------|--------------|
| `fix(pencil): stop graphite breaking when too much pressure applied` | ~~Patch~~ Fix Release |
| `feat(pencil): add 'graphiteWidth' option` | ~~Minor~~ Feature Release |
| `perf(pencil): remove graphiteWidth option`<br/>`BREAKING CHANGE: The graphiteWidth option has been removed. The default graphite width of 10mm is always used for performance reasons.` | ~~Major~~ Breaking Release <br/>(Note that the BREAKING CHANGE:  token must be in the footer of the commit) |

## Key files

- [`.releaserc`](../../.releaserc): semantic-release's configuration file, written in YAML or JSON

## Configuration checklist

Configuration should be made in the `.releaserc` file.

- Adjust the [configuration settings](https://semantic-release.gitbook.io/semantic-release/usage/configuration#branches) to align with your project's branching strategy
- Configure [plugins](https://semantic-release.gitbook.io/semantic-release/usage/plugins) depending on your needs

## Testing

It is recommended that any configuration changes are tested in a simple repository before committing to your main one
