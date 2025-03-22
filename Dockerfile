FROM jenkins/jenkins:jdk17

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
 && rm -rf /var/lib/apt/lists/*

RUN install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
 && chmod a+r /etc/apt/keyrings/docker.asc \
 && echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null \
 && apt-get update \
 && apt-get -q -y install docker-ce \
 && rm -rf /var/lib/apt/lists/*

# Configure Docker to run as non-root user
RUN usermod -aG docker jenkins

# Prepare jenkins
USER jenkins

# Set the number of executors
COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy

# Install Jenkins plugins
#RUN install-plugin-cli.sh \
#    blueocean \
#    cloudbees-bitbucket-branch-source \
#    dockerhub-notification \
#    docker-workflow \
#    gerrit-trigger \
#    git \
#    locale \
#    pipeline-stage-view \
#    swarm \
#    workflow-aggregator

RUN jenkins-plugin-cli --plugins blueocean dockerhub-notification docker-workflow gerrit-trigger git locale pipeline-stage-view swarm workflow-aggregator
