pipeline {
  agent any
  stages {
    stage('create basebox') {
      steps {
        echo 'Build vagrant base boxes ubuntu-18.04'
        sh '   pwd'
        sh 'create-vagrant-box.sh  '
        cleanWs(deleteDirs: true)
      }
    }
  }
}