#!/usr/bin/env bash

function die() {
  echo "Error: $1"
  exit 1
}

image_name="silverpeas/silverdev"
image_version=latest
name="silverdev-${image_version}"
mounts=""
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h|--help)
      echo """Usage:
run.sh [-i [IMAGE_NAME:]IMAGE_VERSION] [-w WORKING_DIR] [-n NAME] [-a APP_DIR] [-d HOST_DIR:LOCAL_DIR]* [-s]

Spawns and runs a container from the Docker image silverpeas/silverdev at a
given version.

In order to build the Silverpeas projects in that container, you have two 
possible options:
- Either mounting the working folder containing the projects in the host on the
  container;
- Either fetching the projects from your SCM in the container.
Your IDE, on the host, could be also accessible to the container by mounting on
it the directory in which it is installed.

The directory into which your Silverpeas web application is deployed (in
development mode) can be also be mounted by using the -d options. This option
can be repeated several times to mount a different versions of Silverpeas web
app root directory.

The script checks if a Maven settings file settings-docker.xml exists in order
to use it in the container. Otherwise, your settings.xml will be used.

The following files or directories will be also used in the container:
- The Maven security configuration settings-security.xml;
- The Git configuration .gitconfig;
- The ssh configuration directory .ssh;
- The GPG configuration directory .gnupg;

With:
  -i [IMAGE_NAME:]IMAGE_VERSION
                the name and the version of the Docker image to instantiate.
                The name is the one with which you have built the Docker image.
                By default the name is silverpeas/silverdev.
                By default the version is latest.
  -w WORKING_DIR
                the path of your working directory to mount. The working folder
                will be mounted on the /home/silveruser/projects directory in
                the container.
                By default nothing to mount. You have to fetch yourself the
                projects.
  -m HOST_DIR:LOCAL_DIR
                Mounts the folder HOST_DIR in the host on the LOCAL_DIR
                directory in the container.
                This option can be repeated several times to mount several
                directories of the host into the container.
  -a APP_DIR    
                the path of the directory in which your IDE is installed or the
                home directory of the IDE. It will be mounted on the 
                /home/silveruser/apps folder in the container. You can also by
                this way to share your other programs with the container.
                By default nothing to mount.
  -n NAME
                a name to give to the container.
                By default silverdev-IMAGE_VERSION.
  -s
                to share the local Maven repository of the host with the
                container.
      """
      exit 0
      ;;
    -i)
      image_version=`echo "$2" | cut -d ':' -f 2`
      test "$2" = "$image_version" || image_name=`echo "$2" | cut -d ':' -f 1`
      shift # past argument
      shift # past value
      ;;
    -w)
      working_dir="-v "$2":/home/silveruser/projects"
      shift # past argument
      shift # past value
      ;;
    -a)
      app_dir="-v "$2":/home/silveruser/apps"
      shift # past argument
      shift # past value
      ;;
    -n)
      name="$2"
      shift # past argument
      shift # past value
      ;;
    -m)
      mounts="$mounts -v $2"
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
docker run -it -e DISPLAY=${DISPLAY} ${working_dir} ${app_dir} ${maven_repo} ${mounts} \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "${settings}":/home/silveruser/.m2/settings.xml \
  -v "$HOME"/.m2/settings-security.xml:/home/silveruser/.m2/settings-security.xml \
  -v "$HOME"/.gitconfig:/home/silveruser/.gitconfig \
  -v "$HOME"/.ssh:/home/silveruser/.ssh \
  -v "$HOME"/.gnupg:/home/silveruser/.gnupg \
  --privileged \
  --name ${name} \
  ${image_name}:${image_version} /bin/bash
