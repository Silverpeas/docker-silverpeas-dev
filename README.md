# docker-silverpeas-dev

A `Dockerfile` that produces a Docker image to build a [Silverpeas 6](http://www.silverpeas.org) 
project.

Such an image is dedicated to the developers that wish to have an environment ready to build 
(compile and test) a Silverpeas project and this in a reproducible way, without having to be worried 
about specific tools to install or specific settings required for the tests to run correctly.

## Image creation

To create an image, just do:

	$ ./build.sh

this will build an image to work on the latest version of Silverpeas as defined in the `Dockerfile` 
with the tag `silverpeas/sivlerdev:latest`.

Otherwise, to create an image to build a given version of Silverpeas 6, you have to specify as argument 
both the version of Silverpeas followed by the exact version of Wildfly used by this version:

	$ ./build.sh -v 6.0 10.1.0

This will build a Docker image with the tag `silverpeas/silverdev:6.0`. It is to work on a 
Silverpeas 6.0 project and with Wildfly 10.1.0. Here, the version of Silverpeas passed as argument 
isn't in fact important; it just a convention stipulating that a tag of an image is the version
of the Silverpeas projects for which it was created. By doing so, it will be easy for the developer
to switch between different containers, each of them prepared for a different version of Silverpeas.
But the version of Wildfly passed as argument is important because a Wildfly distribution preconfigured 
for the integration tests will be downloaded and in general, for each version of Silverpeas 
(stable or in-development version) matches a given version of Wildfly.

The image is created to start a container with a default user (`silveruser`). 1000 is his identifier
and `users` (group identifier 100) is its main group.
In order to avoid permissions problems with the source code that is shared between the host and the
container, it is required that the identifier of your account in your host is the same that the 
identifier of the default user in the container. In the case your user identifier isn't 1000, then you have to
create an image by specifying the identifier in the command line as following (here, in our example,
the user identifier is 1026):

	$ ./build.sh -u 1026

or

	$ ./build.sh -v 6.0 10.1.0 -u 1026

for creating a Docker image for Silverpeas 6.0 projects and with Wildfly 10.1.0.

## Container running

To run a container `silverdev` from the lastest version of the image, just do:

	$ ./run.sh "$HOME"/Projects

or for a given version, say 6.0:

	$ ./run.sh "$HOME"/Projects 6.0

where the first parameter is the path of the directory that will contain (or that already contains) 
the source code of some Silverpeas projects. This directory will be shared between your host the
the container. The script bootstraps a container with the following name `silverdev-latest` for the
former and `silverdev-6.0` for the latter.

The script will link the following directories and files in your home `.ssh`, `.gnupg`, 
`.m2/settings.xml`, `.m2/settings-security.xml` and `.gitconfig` to those of the default user in the
container. By doing so, any build performed within the container will be able to fetch dependencies, 
to sign the source code, to deploy the software artifacts into a Nexus server and to commit and
push into a Git remote repository. 

If you requirement is just to build a Silverpeas project (id est compiling and testing), then
you don't have to link these directories and files. You can then run a container as
following:

	$ docker run -it \
	       -v "$HOME"/Projects:/home/silveruser/Projects \ 
	       silverpeas/silverdev /bin/bash
 
If your requirement is also to commit and push into a remote Git repository, then link your
`.gitconfig` file as following:

	$ docker run -it \ 
	       -v "$HOME"/Projects:/home/silveruser/Projects \ 
	       -v "$HOME"/.gitconfig:/home/silveruser/.gitconfig \
	       silverpeas/silverdev /bin/bash


