#!/usr/bin/env bash

function die() {
  echo "Error: $1"
  exit 1
}

function checkNotEmpty() {
  test "Z$1" != "Z" || die "Parameter is empty"
}

name="silverpeas/silverdev"
version=$(grep -oP '(?<=version=")[0-9]+.[0-9]+(.[0-9]+)?' Dockerfile)
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h|--help)
      w=`grep "ARG WILDFLY_VERSION" Dockerfile | cut -d '=' -f 2 | xargs`
      j=`grep "ARG JAVA_VERSION" Dockerfile | cut -d '=' -f 2 | xargs`
      u=`grep "ARG USER_ID" Dockerfile | cut -d '=' -f 2 | xargs`
      g=`grep "ARG GROUP_ID" Dockerfile | cut -d '=' -f 2 | xargs`
      echo """Usage: build.sh [-u USER_ID]
                [-g GROUP_ID]
                [-w WILDFLY_VERSION]
                [-j JAVA_VERSION]
                [-v IMAGE_VERSION]
                [-n IMAGE_NAME]

Build a Docker image from which a Docker container could be spawned to code and
build within a compartmentalized environment some Silverpeas projects that can 
be shared between the container and the host.

With:
  -u USER_ID    
                set the user identifier as USER_ID. The USER_ID should be your
                own user identifier on the host in the case some resources have
                to be shared between the Docker container and the host.
                By default $u.
  -g GROUP_ID   
                set the group identifier as GROUP_ID. The GROUP_ID should be
                your own group identifier on the host in the case some 
                resources have to be shared between the Docker container and
                the host.
                By default $g.
  -w WILDFLY_VERSION
                set the version of the Widfly distribution to use for running
                the integration tests.
                By default $w.
  -j JAVA_VERSION
                set the version of the JDK to use for building, testing and
                running Silverpeas.
                By default $j.
   -v IMAGE_VERSION
                the version of the Docker image to build. Should be equal to
                the version of Silverpeas for which the Docker image is.
                By default $version.
   -n IMAGE_NAME
                the name of the image to build. It's strongly not recommended 
                to modify it.
                By default $name.
      """
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
      sed -i -e "s/WILDFLY_HOME=\/opt\/wildfly-for-tests\/wildfly-[0-9.]\+.Final/WILDFLY_HOME=\/opt\/wildfly-for-tests\/wildfly-${wildfly_version}.Final/g" src/wildfly
      ;;
    -v)
      checkNotEmpty "$2"
      version="$2"
      shift # past argument
      shift # past first value
      ;;
    -j)
      checkNotEmpty "$2"
      java_version="--build-arg JAVA_VERSION=$2"
      shift # past argument
      shift # past first value
      ;;
    -n)
      checkNotEmpty "$2"
      name="$2"
      shift # past argument
      shift # past first value
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

# check the version already exists
if git rev-parse "$version" >/dev/null 2>&1; then
  git checkout $version
fi

# build the Docker image for building some of the Silverpeas projects
docker build $user $group $wildfly_version $java_version \
    -t $name:$version \
    .

