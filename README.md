# docker-silverpeas-dev

A `Dockerfile` that produces a Docker image to build a [Silverpeas 6](http://www.silverpeas.org) 
project.

Such an image is dedicated for the developers that wish to have an environment ready to develop,  build 
(compile and test) a Silverpeas project and this in a reproducible way, without having to be worried 
about specific tools to install or specific settings required for the tests to be executed correctly.

## Image creation

To create an image, just do:

	$ ./build.sh

this will build an image to work on the latest version of Silverpeas and with the latest supported
version of Wildfly as defined in the `Dockerfile` with the tag `silverpeas/silverdev:<version>` where
`<version>` is the version number set in the `version` parameter of the `LABEL` tag in the `Dockerfile`.

To specify both a given version of Wildfly (here Wildfly 10.1.0) to use and the version of Silverpeas for
which the image has to be built (here for Silverpeas 6.0), just do:

	$ ./build.sh -w 10.1.0 -v 6.0

This will first check if the tag `6.0` already exists and in this case it will checkout to the revision hash 
corresponding to the specified tag. Then this will build a Docker image with the tag `silverpeas/silverdev:6.0`
by using the current `Dockerfile` in the sources.

By convention, the major/minor version of the Docker image should be the same as the major/minor version of Silverpeas for 
which the image is dedicated. For each major/minor version of Silverpeas matches a version of the Docker image; 
the patch version of the Docker image is for the corrective version of the image itself. If the Docker image
is built from a `Dockerfile` in a given version that doesn't match the version of Silverpeas for which the
image is built, then unexpected behaviours can be encountered when using any containers spawn from such
an image; indeed, the development and build environment set in the image can differ from the environment 
expected by the version of Silverpeas for which the image has been built.

The convention to match the major/minor version of the Docker image with a major/minor version of Silverpeas is 
mainly for information so, by doing so, it will be easy for the developer to switch between
different containers, each of them prepared for a different version of Silverpeas. Only the `latest` 
Docker image version, built by DockerHub, matches the current in-development major or minor version of 
Silverpeas (branch `master`).
Nevertheless, the version of Wildfly passed as argument is important because a Wildfly distribution 
preconfigured for the integration tests will be downloaded and in general, for each version of Silverpeas 
(stable or in-development version) matches a given version of Wildfly.

The image is created to start a container with a default user (`silveruser`). 1000 is his identifier
and `users` (group identifier 100) is its main group.
In order to avoid permissions problems with the resources shared with the host (like the user Maven settings
or the local Maven repository on the host), it is required that the identifier of your account in your host is the same that the 
identifier of the default user in the container. In the case your user identifier isn't 1000, then you have to
create an image by specifying the identifier in the command line as following (here, in our example,
the user identifier is 1026):

	$ ./build.sh -u 1026

or

	$ ./build.sh -v 6.0 10.1.0 -u 1026

for creating a Docker image for Silverpeas 6.0 projects and with Wildfly 10.1.0.

For more information about the script, just do:

	$ ./build.sh -h

## Container running

To run a container `silverdev` from the latest version of the image, just do:

	$ ./run.sh -n dev-myproject -s

or for a given version, say 6.0:

	$ ./run.sh -i 6.0 -n dev-myproject -s

where `dev-myproject` is the name of the container to spawn and the flag `-s` is to specify the local Maven 
repository of the user has to be shared with the container. 

In the case the code of your Silverpeas projects are on the host, in order to share them with the container,
just do:

	$ ./run.sh -i 6.0 -n dev-myproject -s -w ${HOME}/MyProjects

where `MyProjects` is the directories in which are stored your Silverpeas projects. This directory will
be mounted on `/home/silveruser/projects` in the container.


The script will link the following directories and files in your home `.ssh`, `.gnupg`, 
`.m2/settings.xml`, `.m2/settings-security.xml` and `.gitconfig` to those of the default user in the
container. By doing so, any build performed within the container will be able to fetch dependencies, 
to sign the source code, to deploy the software artifacts into a Nexus server and to commit and
push into a Git remote repository. 

If your requirement is just to build a Silverpeas project (id est compiling and testing), then
you don't have to link these directories and files. You can then run a container as
following:

	$ docker run -it \
	       -v "$HOME"/Projects:/home/silveruser/projects \ 
	       silverpeas/silverdev /bin/bash
 
If your requirement is also to commit and push into a remote Git repository, then link your
`.gitconfig` file as following:

	$ docker run -it \ 
	       -v "$HOME"/Projects:/home/silveruser/projects \ 
	       -v "$HOME"/.gitconfig:/home/silveruser/.gitconfig \
	       silverpeas/silverdev /bin/bash


