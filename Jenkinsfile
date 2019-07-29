pipeline {
  agent any
  stages {
    stage('create basebox') {
      steps {
        echo 'Build vagrant base boxes ubuntu-18.04'
        sh '   pwd'
        sh 'cat create-vagrant-box.sh  | bash'
        cleanWs(deleteDirs: true)
      }
    }
  }
}