#!/bin/bash

set -xe

DOCKER_REPO=docker.io/bgaillard

docker run \
    --rm \
    --privileged \
    -v $(realpath ./):/tmp/src \
    -v $(realpath ./):/tmp/dockerfile \
    -v $HOME/.docker:/root/.docker \
    --entrypoint buildctl-daemonless.sh \
    moby/buildkit:master \
    build \
    --frontend dockerfile.v0 \
    --local context=/tmp/src \
    --local dockerfile=/tmp/dockerfile \
    --output type=image,name=${DOCKER_REPO}/test:1,push=true \
    --export-cache type=registry,ref=${DOCKER_REPO}/test:cache,mod=max,push=true \
    --import-cache type=registry,ref=${DOCKER_REPO}/test:cache
