#!/usr/bin/env bash

function die() {
  echo "Error: $1"
  exit 1
}

image_version=latest
name="silverdev-${image_version}"
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h)
      echo "Usage: run.sh [-i IMAGE_VERSION] [-w WORKING_DIR] [-n NAME] [-s]"
      echo "Spawns and runs a container from the Docker image silverpeas/silverdev at a given version."
      echo "In order to build the projects in that container, the working directory of your projects"
      echo "will be mounted in the container. It checks if a Maven settings settings-docker.xml exist"
      echo "in order to use it in the container. Otherwise, it is your settings.xml that will be used."
      echo "The following files or directories will be also used in the container: "
      echo " - The Maven security configuration settings-security.xml"
      echo " - The Git configuration .gitconfig"
      echo " - The ssh configuration directory .ssh"
      echo " - The GPG configuration directory .gnupg"
      echo ""
      echo "with:"
      echo "   -i IMAGE_VERSION  the version of the Docker image to instantiate. By default latest."
      echo "   -w WORKING_DIR    the path of your working directory to mount The working directory"
      echo "                     will be mounted to /home/silveruser/projects. By default nothing to"
      echo "                     mount."
      echo "   -n NAME           a name to give to the container. By default silverdev-IMAGE_VERSION."
      echo "   -s                to share the local Maven repository of the host with the container."
      exit 0
      ;;
    -i)
      image_version="$2"
      shift # past argument
      shift # past value
      ;;
    -w)
      working_dir="-v "$2":/home/silveruser/projects"
      shift # past argument
      shift # past value
      ;;
    -n)
      name="$2"
      shift # past argument
      shift # past value
      ;;
    -s)
      maven_repo="-v ${HOME}/.m2/repository:/home/silveruser/.m2/repository"
      shift # past argument
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

# run the silverpeas build image by linking the required volumes for signing and deploying built artifacts.
if [[ -f "$HOME"/.m2/settings-docker.xml ]]; then
  settings="$HOME"/.m2/settings-docker.xml
else
  settings="$HOME"/.m2/settings.xml
fi

#xhost +si:localuser:$USER
docker run -it -e DISPLAY=${DISPLAY} ${working_dir} ${maven_repo} \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "${settings}":/home/silveruser/.m2/settings.xml \
  -v "$HOME"/.m2/settings-security.xml:/home/silveruser/.m2/settings-security.xml \
  -v "$HOME"/.gitconfig:/home/silveruser/.gitconfig \
  -v "$HOME"/.ssh:/home/silveruser/.ssh \
  -v "$HOME"/.gnupg:/home/silveruser/.gnupg \
  --name ${name} \
  silverpeas/silverdev:${image_version} /bin/bash
