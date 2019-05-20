#!/usr/bin/env bash

function die() {
  echo "Error: $1"
  exit 1
}

function checkNotEmpty() {
  test "Z$1" != "Z" || die "Parameter is empty"
}

version=0
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -u)
      user="--build-arg USER_ID=$2"
      shift # past argument
      shift # past value
      ;;
    -v)
      silverpeas_version="$2"
      wildfly_version="$3"
      checkNotEmpty ${silverpeas_version}
      checkNotEmpty ${wildfly_version}
      version=1
      shift # past argument
      shift # past first value
      shift # past second value
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done


# build the Docker image for building some of the Silverpeas projects
if [[ ${version} -eq 1 ]]; then
  docker build ${user} \
    --build-arg WILDFLY_VERSION=${wildfly_version} \
    -t silverpeas/silverdev:${silverpeas_version} \
    .
else
  docker build ${user} \
    -t silverpeas/silverdev:latest \
    .
fi

