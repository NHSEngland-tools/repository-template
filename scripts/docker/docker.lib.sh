#!/bin/bash

# WARNING: Please, DO NOT edit this file! It is maintained in the Repository Template (https://github.com/nhs-england-tools/repository-template). Raise a PR instead.

set -euo pipefail

# A set of Docker functions written in Bash.
#
# Usage:
#   $ source ./docker.lib.sh
#
# Arguments (provided as environment variables):
#   DOCKER_IMAGE=ghcr.io/org/repo   # Docker image name
#   DOCKER_TITLE="My Docker image"  # Docker image title

# ==============================================================================
# Functions to be used with custom images.

# Build Docker image.
# Arguments (provided as environment variables):
#   dir=[path to the Dockerfile to use, default is '.']
function docker-build() {

  local dir=${dir:-$PWD}
  _create-effective-dockerfile
  version-create-effective-file
  docker build \
    --progress=plain \
    --platform linux/amd64 \
    --build-arg IMAGE="${DOCKER_IMAGE}" \
    --build-arg TITLE="${DOCKER_TITLE}" \
    --build-arg DESCRIPTION="${DOCKER_TITLE}" \
    --build-arg LICENCE=MIT \
    --build-arg GIT_URL="$(git config --get remote.origin.url)" \
    --build-arg GIT_BRANCH="$(_get-git-branch-name)" \
    --build-arg GIT_COMMIT_HASH="$(git rev-parse --short HEAD)" \
    --build-arg BUILD_DATE="$(date -u +"%Y-%m-%dT%H:%M:%S%z")" \
    --build-arg BUILD_VERSION="$(_get-version)" \
    --tag "${DOCKER_IMAGE}:$(_get-version)" \
    --rm \
    --file "${dir}/Dockerfile.effective" \
    .
  # Tag the image with all the stated versions, see the documentation for more details
  for version in $(_get-all-versions) latest; do
    docker tag "${DOCKER_IMAGE}:$(_get-version)" "${DOCKER_IMAGE}:${version}"
  done
  docker rmi --force "$(docker images | grep "<none>" | awk '{print $3}')" 2> /dev/null ||:
}

# Check test Docker image.
# Arguments (provided as environment variables):
#   args=[arguments to pass to Docker to run the container, default is none/empty]
#   cmd=[command to pass to the container for execution, default is none/empty]
#   dir=[path to the image directory where the Dockerfile is located, default is '.']
#   check=[output string to search for]
function docker-check-test() {

  local dir=${dir:-$PWD}
  # shellcheck disable=SC2086,SC2154
  docker run --rm --platform linux/amd64 \
    ${args:-} \
    "${DOCKER_IMAGE}:$(_get-version)" 2>/dev/null \
    ${cmd:-} \
  | grep -q "${check}" && echo PASS || echo FAIL
}

# Run Docker image.
# Arguments (provided as environment variables):
#   args=[arguments to pass to Docker to run the container, default is none/empty]
#   cmd=[command to pass to the container for execution, default is none/empty]
#   dir=[path to the image directory where the Dockerfile is located, default is '.']
function docker-run() {

  local dir=${dir:-$PWD}
  # shellcheck disable=SC2086
  docker run --rm --platform linux/amd64 \
    ${args:-} \
    "${DOCKER_IMAGE}:$(dir="$dir" _get-version)" \
    ${cmd:-}
}

# Push Docker image.
# Arguments (provided as environment variables):
#   dir=[path to the image directory where the Dockerfile is located, default is '.']
function docker-push() {

  local dir=${dir:-$PWD}
  # Push all the image tags based on the stated versions, see the documentation for more details
  for version in $(dir="$dir" _get-all-versions) latest; do
    docker push "${DOCKER_IMAGE}:${version}"
  done
}

# Remove Docker resources.
# Arguments (provided as environment variables):
#   dir=[path to the image directory where the Dockerfile is located, default is '.']
function docker-clean() {

  local dir=${dir:-$PWD}
  for version in $(dir="$dir" _get-all-versions) latest; do
    docker rmi "${DOCKER_IMAGE}:${version}" > /dev/null 2>&1 ||:
  done
  rm -f \
    .version \
    Dockerfile.effective
}

# Create effective version from the VERSION file.
# Arguments (provided as environment variables):
#   dir=[path to the VERSION file to use, default is '.']
#   BUILD_DATETIME=[build date and time in the '%Y-%m-%dT%H:%M:%S%z' format generated by the CI/CD pipeline, default is current date and time]
function version-create-effective-file() {

  local dir=${dir:-$PWD}
  build_datetime=${BUILD_DATETIME:-$(date -u +'%Y-%m-%dT%H:%M:%S%z')}
  if [ -f "$dir/VERSION" ]; then
    # shellcheck disable=SC2002
    cat "$dir/VERSION" | \
      sed "s/yyyy/$(date --date="${build_datetime}" -u +"%Y")/g" | \
      sed "s/mm/$(date --date="${build_datetime}" -u +"%m")/g" | \
      sed "s/dd/$(date --date="${build_datetime}" -u +"%d")/g" | \
      sed "s/HH/$(date --date="${build_datetime}" -u +"%H")/g" | \
      sed "s/MM/$(date --date="${build_datetime}" -u +"%M")/g" | \
      sed "s/SS/$(date --date="${build_datetime}" -u +"%S")/g" | \
      sed "s/hash/$(git rev-parse --short HEAD)/g" \
    > "$dir/.version"
  fi
}

# ==============================================================================
# Functions to be used with external images.

# Retrieve the Docker image version from the '.tool-versions' file and pull the
# image if required. This function is to be used in conjunction with the
# external images and it prevents Docker from downloading an image each time it
# is used, since the digest is not stored locally for compressed images. To
# optimise, the solution is to pull the image using its digest and then tag it,
# checking this tag for existence for any subsequent use.
# Arguments (provided as environment variables):
#   name=[full name of the Docker image]
# shellcheck disable=SC2001
function docker-get-image-version-and-pull() {

  # Get the image full version from the '.tool-versions' file
  versions_file="$(git rev-parse --show-toplevel)/.tool-versions"
  version="latest"
  if [ -f "$versions_file" ]; then
    line=$(grep "docker/${name} " "$versions_file" | sed "s/^#\s*//; s/\s*#.*$//")
    [ -n "$line" ] && version=$(echo "$line" | awk '{print $2}')
  fi

  # Split the image version into two, tag name and digest sha256.
  # E.g. for the given entry "docker/image 1.2.3@sha256:hash" in the
  # '.tool-versions' file, the following variables will be set:
  #   version="1.2.3@sha256:hash"
  #   tag="1.2.3"
  #   digest="sha256:hash"
  tag="$(echo "$version" | sed 's/@.*$//')"
  digest="$(echo "$version" | sed 's/^.*@//')"

  # Check if the image exists locally already
  if ! docker images | grep -q "${name}.*${tag}"; then
    if [ "$digest" != "latest" ]; then
      # Pull image by the digest sha256 and tag it
      docker pull \
        --platform linux/amd64 \
        "${name}@${digest}" \
      > /dev/null 2>&1 || true
      docker tag "${name}@${digest}" "${name}:${tag}"
    else
      # Pull the latest image
      docker pull \
        --platform linux/amd64 \
        "${name}:latest" \
      > /dev/null 2>&1 || true
    fi
  fi

  echo "${name}:${version}"
}

# ==============================================================================
# "Private" functions.

# Create effective Dockerfile.
# Arguments (provided as environment variables):
#   dir=[path to the image directory where the Dockerfile is located, default is '.']
function _create-effective-dockerfile() {

  local dir=${dir:-$PWD}
  cp "${dir}/Dockerfile" "${dir}/Dockerfile.effective"
  _replace-image-latest-by-specific-version
  _append-metadata
}

# Replace image:latest by a specific version.
# Arguments (provided as environment variables):
#   dir=[path to the image directory where the Dockerfile is located, default is '.']
function _replace-image-latest-by-specific-version() {

  local dir=${dir:-$PWD}
  versions_file=$(git rev-parse --show-toplevel)/.tool-versions
  if [ -f "$versions_file" ]; then
    # First, list the entries specific for Docker to take precedence, then the rest
    content=$(grep " docker/" "$versions_file"; grep -v " docker/" "$versions_file")
    echo "$content" | while IFS= read -r line; do
      [ -z "$line" ] && continue
      line=$(echo "$line" | sed "s/^#\s*//; s/\s*#.*$//" | sed "s;docker/;;")
      name=$(echo "$line" | awk '{print $1}')
      version=$(echo "$line" | awk '{print $2}')
      sed -i "s;FROM ${name}:latest;FROM ${name}:${version};g" "${dir}/Dockerfile.effective"
    done
  fi
}

# Append metadata to the end of Dockerfile.
# Arguments (provided as environment variables):
#   dir=[path to the image directory where the Dockerfile is located, default is '.']
function _append-metadata() {

  local dir=${dir:-$PWD}
  cat \
    "$dir/Dockerfile.effective" \
    "$(git rev-parse --show-toplevel)/scripts/docker/Dockerfile.metadata" \
  > "$dir/Dockerfile.effective.tmp"
  mv "$dir/Dockerfile.effective.tmp" "$dir/Dockerfile.effective"
}

# Print top Docker image version.
# Arguments (provided as environment variables):
#   dir=[path to the image directory where the Dockerfile is located, default is '.']
function _get-version() {

  local dir=${dir:-$PWD}
  head -n 1 "${dir}/.version" 2> /dev/null ||:
}

# Print all Docker image versions.
# Arguments (provided as environment variables):
#   dir=[path to the image directory where the Dockerfile is located, default is '.']
function _get-all-versions() {

  local dir=${dir:-$PWD}
  cat "${dir}/.version" 2> /dev/null ||:
}

# Print Git branch name. Check the GitHub variables first and then the local Git
# repo.
function _get-git-branch-name() {

  branch_name=$(git rev-parse --abbrev-ref HEAD)
  if [ -n "${GITHUB_HEAD_REF:-}" ]; then
    branch_name=$GITHUB_HEAD_REF
  elif [ -n "${GITHUB_REF:-}" ]; then
    # shellcheck disable=SC2001
    branch_name=$(echo "$GITHUB_REF" | sed "s#refs/heads/##")
  fi

  echo "$branch_name"
}
