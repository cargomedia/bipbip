#!/usr/bin/env bash

set -e
docker login -u "$DOCKER_USERNAME" -p "$DOCKER_PASSWORD"
export VERSION=$(docker run --rm cargomedia/bipbip bipbip -v | grep -o v.*)
docker tag cargomedia/bipbip:latest cargomedia/bipbip:${VERSION}
docker push cargomedia/bipbip:latest
docker push cargomedia/bipbip:${VERSION}
