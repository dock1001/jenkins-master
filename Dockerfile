FROM jenkins/jenkins:lts

# Install the docker CLI
# https://getintodevops.com/blog/the-simple-way-to-run-docker-in-docker-for-ci
# Also Inspired by https://github.com/Shimmi/docker-jenkins

USER root

RUN apt-get update \
 && apt-get -y install \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg2 \
        software-properties-common \
        mc

RUN curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/dkey; apt-key add /tmp/dkey \
 && add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
    $(lsb_release -cs) \
    stable"
RUN apt-get update \
 && apt-get -q -y install docker-ce

# Spring cleaning
RUN apt-get -q autoremove \
 && apt-get -q clean -y


# Prepare jenkins
USER jenkins

# Set the number of executors
COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy

# Install Jenkins plugins
RUN install-plugins.sh \
    blueocean \
    swarm \
    gerrit-trigger \
    docker-workflow \
    locale \
    workflow-aggregator \
    pipeline-stage-view \
    git \
    cloudbees-bitbucket-branch-source \
    dockerhub-notification \
    github-organization-folder \
    warnings

