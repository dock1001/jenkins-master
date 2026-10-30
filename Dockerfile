FROM jenkins/jenkins:lts-jdk25

# Switch to root to create the JCasC mount point
USER root

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
