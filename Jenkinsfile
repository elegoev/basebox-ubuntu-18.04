pipeline {
  agent any
  stages {
    stage('create basebox') {
      steps {
        echo 'Build vagrant base boxes ubuntu-18.04'
        sh '   pwd'
        sh 'echo create-vagrant-box.sh  | sh'
        cleanWs(deleteDirs: true)
      }
    }
  }
}