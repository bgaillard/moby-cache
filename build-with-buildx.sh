#!/bin/bash

# see https://medium.com/titansoft-engineering/docker-build-cache-sharing-on-multi-hosts-with-buildkit-and-buildx-eb8f7005918e

DOCKER_REPO=docker.io/bgaillard

IMAGE_TAG=${DOCKER_REPO}/test:1
CACHE_TAG=${DOCKER_REPO}/test:cache

docker buildx build \
    -t $IMAGE_TAG \
    -f ./Dockerfile \
    --cache-from=type=registry,ref=$CACHE_TAG \
    --cache-to=type=registry,ref=$CACHE_TAG,mode=max \
    --push \
    --progress=plain \
    .
