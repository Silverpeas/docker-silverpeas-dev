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
    -h)
      echo "Usage: build.sh [-u USER_ID] [-g GROUP_ID] -v [SILVERPEAS_VERSION WILDFLY_VERSION]"
      echo "Build a Docker image from which a Docker container could be spawned to code and build"
      echo "within a compartmentalized environment some Silverpeas projects that can be shared "
      echo "between the container and the host."
      echo "with:"
      echo "   -u USER_ID  set the user identifier as USER_ID (it is recommended the USER_ID is"
      echo "               your own user identifier in the host if the code source is shared"
      echo "               between a Docker container and the host. By default 1000."
      echo "   -g GROUP_ID set the group identifier as GROUP_ID (it is recommended the GROUP_ID is"
      echo "               your own group identifier in the host if the code source is shared"
      echo "               between a Docker container and the host. By default 1000."
      echo "   -v SILVERPEAS_VERSION WILDFLY_VERSION"
      echo "               set both the version of Silverpeas and of the Widfly distribution for"
      echo "               which a docker container will be spawn to work on theses versions."
      echo "               By default, the latest version in development of Silverpeas"
      exit 0
      ;;
    -u)
      user="--build-arg USER_ID=$2"
      shift # past argument
      shift # past value
      ;;
    -g)
      group="--build-arg GROUP_ID=$2"
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
  docker build ${user} ${group} \
    --build-arg WILDFLY_VERSION=${wildfly_version} \
    -t silverpeas/silverdev:${silverpeas_version} \
    .
else
  docker build ${user} ${group} \
    -t silverpeas/silverdev:latest \
    .
fi

