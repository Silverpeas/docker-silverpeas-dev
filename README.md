# docker-silverpeas-dev

A `Dockerfile` that produces a Docker image to build a [Silverpeas 6](https://www.silverpeas.org) 
project.

Such an image is dedicated for the developers that wish to have an environment ready to develop, build 
(compile and test) a Silverpeas project and this in a reproducible way, without having to be worried 
about specific tools to install or specific settings required for the tests to be executed correctly.

## Create the Docker image

To create an image, just do:

	$ ./build.sh

this will build an image `silverpeas/silverdev` with as version the one specified by the label `version` in the `Dockerfile`.
All the main development and testing tools required by a Silvepreas project are defined by the following Docker arguments in the `Dockerfile`:

* `WILDFLY_VERSION` for the Wildfly application server dedicated to the integration tests;
* `JAVA_VERSION` for the JDK version to use;
* `MAVEN_VERSION` for the Maven version to use as build chain tool.

The `build.sh` script takes care of the version of the image (hence for the version of Silverpeas for which dev will be done), the Java version and of the Wildfly version.

By convention, the major/minor version of the Docker image should be the same as the major/minor version of Silverpeas for 
which the dev will be done. For each major/minor version of Silverpeas matches a version of the Docker image; 
the patch version of the Docker image is for the corrective version of the image itself. If the Docker image
is built from a `Dockerfile` in a given version that doesn't match the version of Silverpeas for which the
image is built, then unexpected behaviours can be encountered when using any containers spawn from such
an image; indeed, the development and build environment set in the image can differ from the environment 
expected by the version of Silverpeas for which the image has been built.

The convention to match the major/minor version of the Docker image with a major/minor version of Silverpeas is 
mainly for information so, by doing so, it will be easy for the developer to switch between
different containers, each of them prepared for a different version of Silverpeas. Only the `latest` 
Docker image version, built by DockerHub, matches the current in-development major or minor version of 
Silverpeas (branch `master` or `main`).
Nevertheless, the version of Wildfly passed as argument is important because a Wildfly distribution 
preconfigured for the integration tests will be downloaded and in general, for each version of Silverpeas 
(stable or in-development version) matches a given version of Wildfly.

To specify both a given version of Wildfly (here Wildfly 10.1.0) to use and the version of Silverpeas for
which the image has to be built (here for Silverpeas 6.0), just do:

	$ ./build.sh -w 10.1.0 -v 6.0

This will first check if the tag `6.0` already exists and in this case it will checkout to the revision hash 
corresponding to the specified tag. Then this will build a Docker image with as tag `silverpeas/silverdev:6.0`
by using the current `Dockerfile` in the sources. Otherwise, the Docker image will be built with as tag `silverpeas/silverdev:6.0` with the current state of the sources.

The image is created to start a container with a default user (`silveruser`). 1000 is his identifier (as well as the identifier of his main group) and he will be added to the `users` group.
In order to avoid permissions problems with the resources shared with the host (like the user Maven settings
or the local Maven repository on the host), it is required that the identifier of your account in your host is the same as the identifier of the default user in the container. In the case your user identifier isn't 1000, then you have to
create an image by specifying the identifier in the command line as following (here, in our example,
the user identifier is 1026 and a group identifier 65536):

	$ ./build.sh -u 1026 -g 65536

or

	$ ./build.sh -v 6.0 10.1.0 -u 1026 -g 65536

for creating a Docker image for Silverpeas 6.0 projects and with Wildfly 10.1.0.

For more information about the script, just do:

	$ ./build.sh -h

## Run the Docker container

### By using the available script

To run a container `silverdev` from the latest version of the image, just do:

	$ ./run.sh -n dev-myproject -s

or for a given version, say 6.0:

	$ ./run.sh -i 6.0 -n dev-myproject -s

where `dev-myproject` is the name of the container to spawn and the flag `-s` is to specify the local Maven 
repository of the user has to be shared with the container. 

In the case the code of your Silverpeas projects are on the host, in order to share them with the container,
just do:

	$ ./run.sh -i 6.0 -n dev-myproject -s -w ${HOME}/MyProjects

where `MyProjects` is the directory in which are stored your Silverpeas projects. This directory will
be mounted on `/home/silveruser/projects` in the container.

The container spwaned from the image doesn't contain any IDEs. It is only to build Silverpeas projects in a reproducible way. If you expect to develop mainly within a Docker container, we recommend strongly to use instead a [development container](https://containers.dev/). Otherwise, you have either to download and install by 
yourself your preferred IDE in the container (for Unix hosts only for remote X displaying) or to share your IDE on the host with the container. For latter, just run the container as following:

	$ ./run.sh -n dev-myproject -s -a ${HOME}/MyApps

where `MyApps` is the directory in which are installed both your IDE and others programs you wish to use 
within the container. Don't forget to link the application binaries in the `/home/silveruser/bin` directory so
that you will just have to type the command (the `/home/silveruser/bin` directory is in the PATH).

### By your own

The script above will also link the following directories and files in your home user directory: `.ssh`, `.gnupg`, 
`.m2/settings.xml`, `.m2/settings-security.xml` and `.gitconfig` for the default user in the
container. By doing so, any build performed within the container will be able to fetch dependencies, 
to sign the source code, to deploy the software artifacts into a remote Maven repository and to commit and
push into a remote Git repository. 

If your requirement is just to build a Silverpeas project (id est compiling and testing), then
you don't have to link these directories and files. You can then run a container as
following:

	$ docker run -it \
	       -v "$HOME"/Projects:/home/silveruser/projects \ 
		   -v "$HOME"/Apps:/home/silveruser/apps \
	       silverpeas/silverdev /bin/bash
 
If your requirement is also to commit and push into a remote Git repository, then link your
`.gitconfig` file as following:

	$ docker run -it \ 
	       -v "$HOME"/Projects:/home/silveruser/projects \
		   -v "$HOME"/Apps:/home/silveruser/apps \
	       -v "$HOME"/.gitconfig:/home/silveruser/.gitconfig \
	       silverpeas/silverdev /bin/bash

And if you use Generative IA to facilite your devs, then you can also add its configuration files as following (Claude in the example):

	$ docker run -it \ 
	       -v "$HOME"/Projects:/home/silveruser/projects \
		   -v "$HOME"/Apps:/home/silveruser/apps \
	       -v "$HOME"/.gitconfig:/home/silveruser/.gitconfig \
		   -v "$HOME/.claude:/home/silveruser/.claude \
	       silverpeas/silverdev /bin/bash

