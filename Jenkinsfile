pipeline {
    agent {
        docker {
            image 'node:14'
        }
    }
    stages {
        stage("build") {
            steps {
                dir("docs/explorer") {
                    sh '''
                        yarn install --production --frozen-lockfile
                        yarn build
                    '''
                    archiveArtifacts artifacts: "public/*"
                }
            }
        }
    }
}