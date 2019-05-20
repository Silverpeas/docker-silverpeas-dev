#!/usr/bin/env bash

function die() {
  echo "Error: $1"
  exit 1
}

if [[ $# -eq 1 ]]; then
  image_version=$1
else
  image_version=latest
fi

# run the silverpeas build image by linking the required volumes for signing and deploying built artifacts.
docker run -it -v "$HOME"/.m2/settings.xml:/home/silveruser/.m2/settings.xml \
  -v "$HOME"/.m2/settings-security.xml:/home/silveruser/.m2/settings-security.xml \
  -v "$HOME"/.gitconfig:/home/silveruser/.gitconfig \
  -v "$HOME"/.ssh:/home/silveruser/.ssh \
  -v "$HOME"/.gnupg:/home/silveruser/.gnupg \
  --name silverdev-${image_version} \
  silverpeas/silverdev:${image_version} /bin/bash