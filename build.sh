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
      echo "Usage: build.sh [-u USER_ID] [-g GROUP_ID] [-w WILDFLY_VERSION] [-j JAVA_VERSION] [-v IMAGE_VERSION]"
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
      echo "   -w WILDFLY_VERSION"
      echo "               set the version of the Widfly distribution  to use in the integration"
      echo "               tests. By default, the latest supported version of Wildfly."
      echo "   -j JAVA_VERSION"
      echo "               set the version of the JDK to use for building, testing and running Silverpeas"
      echo "   -v IMAGE_VERSION"
      echo "               the version of the Docker image to build. Should be equal to the"
      echo "               version of Silverpeas for which the Docker image is."
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
    -w)
      checkNotEmpty "$2"
      wildfly_version="--build-arg WILDFLY_VERSION=$2"
      shift # past argument
      shift # past first value
      ;;
    -v)
      checkNotEmpty "$2"
      silverpeas_version="$2"
      version=1
      shift # past argument
      shift # past first value
      ;;
    -j)
      checkNotEmpty "$2"
      java_version="--build-arg JAVA_VERSION=$2"
      shift # past argument
      shift # past first value
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done


# build the Docker image for building some of the Silverpeas projects
if [[ ${version} -eq 1 ]]; then
  docker build ${user} ${group} ${wildfly_version} ${java_version} \
    -t silverpeas/silverdev:${silverpeas_version} \
    .
else
  docker build ${user} ${group} ${wildfly_version} ${java_version} \
    -t silverpeas/silverdev:latest \
    .
fi

