FROM jenkins/jenkins:lts-jdk21

# Install the docker CLI
# https://getintodevops.com/blog/the-simple-way-to-run-docker-in-docker-for-ci
# Also Inspired by https://github.com/Shimmi/docker-jenkins

# Switch to root to install packages
USER root

# Install Docker CLI (the daemon is provided by the host via the mounted socket)
RUN apt-get update \
 && apt-get -y install --no-install-recommends ca-certificates curl \
 && install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
 && chmod a+r /etc/apt/keyrings/docker.asc \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list \
 && apt-get update \
 && apt-get -y install --no-install-recommends docker-ce-cli docker-buildx-plugin \
 && rm -rf /var/lib/apt/lists/*

# Allow the jenkins user to use the docker socket
RUN groupadd -f docker && usermod -aG docker jenkins

# Mount point for opt-in JCasC files, empty by default (see CASC_JENKINS_CONFIG below)
RUN install -d -o jenkins -g jenkins /var/jenkins_casc

# Switch back to Jenkins user
USER jenkins

# Install Jenkins plugins
COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Jenkins Configuration as Code: the built-in file, plus any JCasC files mounted
# at /var/jenkins_casc (opt-in, e.g. credentials). The folder is empty by default.
ENV CASC_JENKINS_CONFIG=/usr/share/jenkins/ref/casc/jenkins.yaml,/var/jenkins_casc
COPY --chown=jenkins:jenkins casc/jenkins.yaml /usr/share/jenkins/ref/casc/jenkins.yaml
