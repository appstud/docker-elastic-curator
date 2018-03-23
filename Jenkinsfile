pipeline {
  agent any
  stages {
    stage('Clone') {
        steps {
            git(url: 'git@bitbucket.org:appstud/elastic-curator.git', branch: "${BRANCH_NAME}", credentialsId: '2e3893d8-6173-498b-832a-3e604a2ffa2f')
        }
    }
    stage('Create Dockerfile') {
        steps {
            script {
                CURATOR_VERSION = sh script: 'cat ./VERSION', returnStdout: true
            }
            sh "echo FROM python:3-alpine > Dockerfile"
            sh "echo WORKDIR /curator >> Dockerfile"
            sh "echo RUN ln -s /curator /root/.curator >> Dockerfile"
            sh "echo RUN pip install elasticsearch-curator==${CURATOR_VERSION} >> Dockerfile"
            sh "echo COPY curator.yml . >> Dockerfile"
            sh "echo COPY actions.yml . >> Dockerfile"
            sh "echo COPY run.sh /. >> Dockerfile"
            sh "echo CMD /run.sh >> Dockerfile"
        }
    }
    stage('Build image') {
        steps {
            script {
                sh "docker build -t elastic-curator:${CURATOR_VERSION} ."
            }
        }
    }
    stage('Push image') {
        steps {
            script {
                def localImage = docker.image("elastic-curator:${CURATOR_VERSION}")
                docker.withRegistry('https://registry.appstud.com', 'registry.appstud.com') {
                    localImage.push("${CURATOR_VERSION}")
                    localImage.push("latest")
                }
            }
        }
    }
  }
}
