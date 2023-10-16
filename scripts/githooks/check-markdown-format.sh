#!/bin/bash

# WARNING: Please, DO NOT edit this file! It is maintained in the Repository Template (https://github.com/nhs-england-tools/repository-template). Raise a PR instead.

set -euo pipefail

# Pre-commit git hook to check the Markdown file formatting rules compliance
# over changed files. This is a markdownlint command wrapper. It will run
# markdownlint natively if it is installed, otherwise it will run it in a Docker
# container.
#
# Usage:
#   $ check={all,staged-changes,working-tree-changes,branch} ./check-markdown-format.sh
#
# Options:
#   BRANCH_NAME=other-branch-than-main  # Branch to compare with, default is `origin/main`
#   FORCE_USE_DOCKER=true               # If set to true the command is run in a Docker container, default is 'false'
#   VERBOSE=true                        # Show all the executed commands, default is `false`
#
# Exit codes:
#   0 - All files are formatted correctly
#   1 - Files are not formatted correctly
#
# Notes:
#   1) Please make sure to enable Markdown linting in your IDE. For the Visual
#   Studio Code editor it is `davidanson.vscode-markdownlint` that is already
#   specified in the `./.vscode/extensions.json` file.
#   2) To see the full list of the rules, please visit
#   https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md

# ==============================================================================

function main() {

  cd "$(git rev-parse --show-toplevel)"

  check=${check:-working-tree-changes}
  case $check in
    "all")
      files="$(find ./ -type f -name "*.md")"
      ;;
    "staged-changes")
      files="$(git diff --diff-filter=ACMRT --name-only --cached "*.md")"
      ;;
    "working-tree-changes")
      files="$(git diff --diff-filter=ACMRT --name-only "*.md")"
      ;;
    "branch")
      files="$( (git diff --diff-filter=ACMRT --name-only "${BRANCH_NAME:-origin/main}" "*.md"; git diff --name-only "*.md") | sort | uniq )"
      ;;
  esac

  if [ -n "$files" ]; then
    if command -v markdownlint > /dev/null 2>&1 && ! is-arg-true "${FORCE_USE_DOCKER:-false}"; then
      files="$files" cli-run-markdownlint
    else
      files="$files" docker-run-markdownlint
    fi
  fi
}

# Run markdownlint natively.
# Arguments (provided as environment variables):
#   files=[files to check]
function cli-run-markdownlint() {

  # shellcheck disable=SC2086
  markdownlint \
    $files \
    --config "$PWD/scripts/config/markdownlint.yaml"
}

# Run markdownlint in a Docker container.
# Arguments (provided as environment variables):
#   files=[files to check]
function docker-run-markdownlint() {

  # shellcheck disable=SC1091
  source ./scripts/docker/docker.lib.sh

  # shellcheck disable=SC2155
  local image=$(name=ghcr.io/igorshubovych/markdownlint-cli docker-get-image-version-and-pull)
  # shellcheck disable=SC2086
  docker run --rm --platform linux/amd64 \
    --volume "$PWD":/workdir \
    "$image" \
      $files \
      --config /workdir/scripts/config/markdownlint.yaml
}

# ==============================================================================

function is-arg-true() {

  if [[ "$1" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$ ]]; then
    return 0
  else
    return 1
  fi
}

# ==============================================================================

is-arg-true "${VERBOSE:-false}" && set -x

main "$@"

exit 0
