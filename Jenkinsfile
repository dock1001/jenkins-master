// Based on 
// - https://getintodevops.com/blog/building-your-first-docker-image-with-jenkins-2-guide-for-developers
// - http://fishi.devtail.io/weblog/2016/11/20/docker-build-pipeline-as-code-jenkins/
node 
{
    // some basic config
    def DOCKERHUB_USERNAME = 'NotDefined'

    def IMAGE_TAG          = (env.BRANCH_NAME == 'master'  ? 'custom' : 'dev')
    //def IMAGE_TAG_SHORT    = IMAGE_TAG.substring(0,1)
    //def IMAGE_TAG_REV      = "${IMAGE_TAG_SHORT}${env.BUILD_NUMBER}"
  
    def PUSH_BUILD_NUMBER  = (env.BRANCH_NAME == 'master')
    

    def IMAGE_ARGS         = '.'
    
    // Workaround a current issue with docker.withRegistry
    // https://issues.jenkins-ci.org/browse/JENKINS-38018 
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'docker-hub-cred-d',
                    usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) 
    {
      sh 'docker login -u "$USERNAME" -p "$PASSWORD"'
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
        // We dont push revisions for 'latest' since we only care about latest
        app.push("${IMAGE_TAG}")
    }
}