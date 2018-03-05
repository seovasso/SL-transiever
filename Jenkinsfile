pipeline {
  agent any
  stages {
    stage('Build docs') {
      steps {
        sh '/var/lib/jenkins/scripts/sl-tr-cntrl-doc.sh'
      }
    }
  }
}