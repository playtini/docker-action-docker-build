#!/bin/sh
# shellcheck disable=SC2001

# https://github.com/flownative/docker-action-docker-build/blob/master/entrypoint.sh

set -o errexit

[[ -z "${INPUT_REGISTRY_USERNAME}" ]] && INPUT_REGISTRY_USERNAME="github"
[[ -z "${INPUT_REGISTRY_DOMAIN}" ]] && INPUT_REGISTRY_DOMAIN="ghcr.io"

git config --global --add safe.directory $GITHUB_WORKSPACE

GIT_TAG=$(echo "${INPUT_TAG_REF}" | sed -e 's|refs/tags/||')
IMAGE_NAME="${INPUT_IMAGE_NAME}"

if [ -n "${INPUT_IMAGE_TAG}" ]; then
    IMAGE_TAG="${INPUT_IMAGE_TAG}"
else
    IMAGE_TAG=$(echo "${GIT_TAG}" | sed -e 's/^v//' | sed -e 's/+.*//')
fi

echo "Building ${IMAGE_NAME}:${IMAGE_TAG} based on Git tag ${GIT_TAG} ..."

echo "Creating build-version.txt file ..."
echo "${GIT_TAG}" > "${GITHUB_WORKSPACE}/build-version.txt"

#docker login -u ${INPUT_REGISTRY_USERNAME} -p "${INPUT_REGISTRY_PASSWORD}" https://${INPUT_REGISTRY_DOMAIN}
echo "${INPUT_REGISTRY_PASSWORD}" | docker login -u ${INPUT_REGISTRY_USERNAME} --password-stdin https://${INPUT_REGISTRY_DOMAIN}

echo "=== workspace ==="
ls -l

git checkout "${GIT_TAG}"
set -- "-t" "${IMAGE_NAME}:${IMAGE_TAG}" \
  "--label" "org.label-schema.schema-version=1.0" \
  "--label" "org.label-schema.version=${IMAGE_TAG}" \
  "--label" "org.label-schema.build-date=$(date '+%FT%TZ')"

if [ -n "${INPUT_GIT_REPOSITORY_URL}" ]; then
  set -- "$@" "--label" "org.label-schema.vcs-url=${INPUT_GIT_REPOSITORY_URL}"
fi
if [ -n "${INPUT_GIT_SHA}" ]; then
  set -- "$@" "--label" "org.label-schema.vcs-ref=${INPUT_GIT_SHA}"
fi

echo "INPUT_BUILD_ARGS:" ${INPUT_BUILD_ARGS}

if [ -n "${INPUT_BUILD_ARGS}" ]; then
    for line in $INPUT_BUILD_ARGS
    do
        set -- "$@" "--build-arg" "${line}"
    done
fi

DOCKERFILE_NAME=Dockerfile
if [ -n "${INPUT_DOCKERFILE_NAME}" ]; then
    DOCKERFILE_NAME=$(echo "${INPUT_DOCKERFILE_NAME}")
fi

echo "DOCKERFILE_NAME: ${DOCKERFILE_NAME}"
echo "INPUT_DOCKERFILE_NAME: ${INPUT_DOCKERFILE_NAME}"
echo 'build_args: ' $@

[ -d "./docker" ] && ls -lah ./docker

docker pull "${IMAGE_NAME}:latest" || echo "no latest image"
[ -d "./docker" ] \
    && docker build --network host -f ./docker/"${DOCKERFILE_NAME}" "$@" . \
    || docker build --network host -f ./"${DOCKERFILE_NAME}" "$@" .
docker push "${IMAGE_NAME}:${IMAGE_TAG}"
if [ -n "${INPUT_IMAGE_TAG_2}" ]; then
    docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${IMAGE_NAME}:${INPUT_IMAGE_TAG_2}"
    docker push "${IMAGE_NAME}:${INPUT_IMAGE_TAG_2}"
fi

echo "image_name=${IMAGE_NAME}" >> $GITHUB_OUTPUT
echo "image_tag=${IMAGE_TAG}" >> $GITHUB_OUTPUT
echo "git_tag=${GIT_TAG}" >> $GITHUB_OUTPUT
