#!/usr/bin/env groovy
// Based on
// - https://getintodevops.com/blog/building-your-first-docker-image-with-jenkins-2-guide-for-developers
// - http://fishi.devtail.io/weblog/2016/11/20/docker-build-pipeline-as-code-jenkins/
node
{
    // some basic config
    def DOCKERHUB_USERNAME = 'NotDefined'

    def IMAGE_TAG          = (env.BRANCH_NAME == 'master'  ? 'latest' : 'dev')

    def IMAGE_ARGS         = '--pull --no-cache .'

    // Log in to Docker Hub; the password is passed on stdin so it never appears on a command line
    withCredentials([usernamePassword(credentialsId: 'docker-hub-cred-d',
                                      usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')])
    {
        sh 'echo "$PASSWORD" | docker login -u "$USERNAME" --password-stdin'
        DOCKERHUB_USERNAME = USERNAME
    }

    def IMAGE_NAME        = "$DOCKERHUB_USERNAME/jenkins-master"

    def app

    stage('Checkout SCM')
    {
        // Let's make sure we have the repository cloned to our workspace
        checkout scm
    }

    stage('Build image')
    {
        // This builds the actual image; synonymous to docker build on the command line
        app = docker.build("${IMAGE_NAME}:${IMAGE_TAG}", "${IMAGE_ARGS}")
    }

    stage('Push image')
    {
        app.push("${IMAGE_TAG}")
    }
}
