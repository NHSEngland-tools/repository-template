#!/bin/bash

# Check Markdown formating of all the "*.md" files that are changed and commited to the current branch.
#
# Usage:
#   $ [options] ./markdown-check-format.sh
#
# Options:
#   BRANCH_NAME=other-branch-than-main  # Branch to compare with

# Please, make sure to enable Markdown linting in your IDE. For the Visual Studio Code editor it is
# `davidanson.vscode-markdownlint` that is already specified in the `.vscode/extensions.json` file.

files=$((git diff --diff-filter=ACMRT --name-only origin/${BRANCH_NAME:-main}.. "*.md"; git diff --name-only "*.md") | sort | uniq)
if [ -n "$files" ]; then
  image=ghcr.io/igorshubovych/markdownlint-cli@sha256:3e42db866de0fc813f74450f1065eab9066607fed34eb119d0db6f4e640e6b8d # v0.34.0
  docker run --rm \
    -v $PWD:/workdir \
    $image \
      $files \
      --disable MD013 MD033
fi
