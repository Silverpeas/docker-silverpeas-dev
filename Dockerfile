#
# This Dockerfile is for creating an image to bootstrap a container within which one or more
# Silverpeas projects can be developed and built. The development and build environment required
# to work on one or more Silverpeas projects is set and ready in the container. By default, it is an
# IDEA IntelliJ IDE that is installed.
#
# The version of the Docker image is based upon the version of the Silverpeas platform on which the
# development and build environment is set up:
# <Silverpeas major version>.<Silverpeas minor version>.<Docker image patch version>
# For instance, a Docker image with version 6.2.1 means it defines a development and build
# environment for a projet based upon Silverpeas 6.2 and it is the first corrective version of such
# a Docker image. The Silverpeas 6.2 can to be not yet released; in such a case, it means the Docker image is to
# work on the next version of Silverpeas and, once this version is released it is to work on the patch versions of
# this version of Silverpeas.
# By using such a container, we ensure the build is reproductible and doesn't depend on the
# environment context specific to the developer's host. Only the .m2 repository and some settings
# like .m2/settings.xml, .gitconfig, .gnupg and .ssh of the current user in the host are shared with
# the container in order to be able to interact with his remote services.
#
FROM ubuntu:jammy

LABEL name="Silverpeas Dev" description="A Docker image to dev and to build a Silverpeas project" vendor="Silverpeas" version="6.4" build=1
MAINTAINER Miguel Moquillon "miguel.moquillon@silverpeas.org"

ENV TERM=xterm
ENV TZ=Europe/Paris
ENV DEBIAN_FRONTEND=noninteractive

# Parameters whose values are required yfor the tests to succeed
ARG DEFAULT_LOCALE=fr_FR.UTF-8
ARG MAVEN_VERSION=3.9.6
ARG MAVEN_SHA=706f01b20dec0305a822ab614d51f32b07ee11d0218175e55450242e49d2156386483b506b3a4e8a03ac8611bae96395fd5eec15f50d3013d5deed6d1ee18224
ARG WILDFLY_VERSION=26.1.3
ARG JAVA_VERSION=11
ARG GROOVY_VERSION=4.0.20
ARG GROOVY_SHA=fdf70cc57eff997f3fa5aee2b340d311593912e822ad810b3fd6ee403985eb75
ARG NODEJS_VERSION=16

# Because the source code is shared between the host and the container, it is required the identifier
# of the owner and of its group are the same between this two environments. By default, they are both set at 1000.
# The user in the Docker container is also in the group users (id 100 by default)
ARG USER_ID=1000
ARG GROUP_ID=1000

COPY src/maven-deps.zip /tmp/
COPY src/mozilla-firefox /etc/apt/preferences.d/

RUN apt-get update \
  && apt-get install -y software-properties-common \
  && add-apt-repository -y ppa:mozillateam/ppa \
  && apt-get update \
  && apt-get install -y tzdata \
  && apt-get install -y \
    apt-utils \
    iputils-ping \
    vim \
    curl \
    git \
    openssh-client \
    gnupg \
    locales \
    language-pack-en \
    language-pack-fr \
    procps \
    net-tools \
    zip \
    unzip \
    openjdk-${JAVA_VERSION}-jdk \
    openjdk-${JAVA_VERSION}-doc \
    ffmpeg \
    imagemagick \
    ghostscript \
    libreoffice-writer \
    libreoffice-calc \
    libreoffice-impress \
    gpgv \
    bash-completion \
    libgbm1 \
    htop \
    firefox \
  && groupadd -g ${GROUP_ID} silveruser \
  && useradd -u ${USER_ID} -g ${GROUP_ID} -G users -d /home/silveruser -s /bin/bash -m silveruser \
  && curl -sL https://deb.nodesource.com/setup_${NODEJS_VERSION}.x | bash - \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/* \
  && update-ca-certificates -f \
  && mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${MAVEN_SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn \
  && unzip /tmp/maven-deps.zip -d /home/silveruser/ \
  && chown -R silveruser:silveruser /home/silveruser/.m2 \
  && curl -fsSL -o /tmp/apache-groovy.zip https://groovy.jfrog.io/artifactory/dist-release-local/groovy-zips/apache-groovy-binary-${GROOVY_VERSION}.zip \
  && echo "${GROOVY_SHA}  /tmp/apache-groovy.zip" | sha256sum -c - \
  && unzip /tmp/apache-groovy.zip -d /opt/ \
  && echo `grep -oP '(?<=")[a-zA-Z:/]+(?=")' /etc/environment`:/opt/groovy-${GROOVY_VERSION}/bin > /etc/environment \
  && mkdir /home/silveruser/bin \
  && echo "PATH=${PATH}:/home/silveruser/bin" >> /home/silveruser/.bashrc \
  && curl -fsSL -o /tmp/swftools-bin-0.9.2.zip https://www.silverpeas.org/files/swftools-bin-0.9.2.zip \
  && echo 'd40bd091c84bde2872f2733a3c767b3a686c8e8477a3af3a96ef347cf05c5e43 *swftools-bin-0.9.2.zip' | sha256sum - \
  && unzip /tmp/swftools-bin-0.9.2.zip -d / \
  && curl -fsSL -o /tmp/pdf2json-bin-0.68.zip https://www.silverpeas.org/files/pdf2json-bin-0.68.zip \
  && echo 'eec849cdd75224f9d44c0999ed1fbe8764a773d8ab0cf7fff4bf922ab81c9f84 *pdf2json-bin-0.68.zip' | sha256sum - \
  && unzip /tmp/pdf2json-bin-0.68.zip -d / \
  && curl -fsSL -o /tmp/wildfly-${WILDFLY_VERSION}.Final.FOR-TESTS.zip https://www.silverpeas.org/files/wildfly-${WILDFLY_VERSION}.Final.FOR-TESTS.zip \
  && mkdir /opt/wildfly-for-tests \
  && unzip /tmp/wildfly-${WILDFLY_VERSION}.Final.FOR-TESTS.zip -d /opt/wildfly-for-tests/ \
  && chown -R silveruser:users /opt/wildfly-for-tests/ \
  && sed -i 's/\/home\/miguel\/tmp/\/opt\/wildfly-for-tests/g' /opt/wildfly-for-tests/wildfly-${WILDFLY_VERSION}.Final/standalone/configuration/standalone-full.xml \
  && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
  && echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen \
  && echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen \
  && locale-gen \
  && update-locale LANG=${DEFAULT_LOCALE} LANGUAGE=${DEFAULT_LOCALE} LC_ALL=${DEFAULT_LOCALE} \
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
  && dpkg-reconfigure --frontend noninteractive tzdata

COPY src/inputrc /home/silveruser/.inputrc
COPY src/bash_aliases /home/silveruser/.bash_aliases
COPY src/settings.xml /home/silveruser/.m2/
COPY src/git_completion_profile /home/silveruser/.git_completion_profile
COPY src/wildfly /home/silveruser/bin/

RUN chown -R silveruser:silveruser /home/silveruser \
  && echo "if [ -f .git_completion_profile ]; then\n  . ~/.git_completion_profile\nfi" >> /home/silveruser/.bashrc

ENV LANG ${DEFAULT_LOCALE}
ENV LANGUAGE ${DEFAULT_LOCALE}
ENV LC_ALL ${DEFAULT_LOCALE}
ENV MAVEN_HOME /usr/share/maven
ENV JAVA_HOME /usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64
ENV GROOVY_HOME /opt/groovy-${GROOVY_VERSION}

# By default, the build will be done in the default user's home directory
USER silveruser
WORKDIR /home/silveruser

# The GPG and SSL keys to use for respectively signing and then deploying the built artifact to
# our Nexus server have to to be provided by an outside directory; therefore the below definition
# of volumes.
# WARNING: You have to link also two files in order to be able to deploy the build results and to
# push commits:
# - /home/silveruser/.m2/settings.xml and /home/silveruser/.m2/settings-security.xml files with your
# own in order to sign and to deploy the artifact with Maven. In these files the GPG key, the SSL
# passphrase as well as the remote servers must be defined.
# - /home/silveruser/.m2/.gitconfig file with your own in order to be able to push any commits.
VOLUME ["/home/silveruser/.ssh", "/home/silveruser/.gnupg"]
