#!/usr/bin/env groovy
def LOGFILES
pipeline {
    agent { label "${params.SLAVE}" }
    options {
        timestamps()
    }

    environment {
        // Define test branches and device services
        PROFILELIST = 'device-virtual,device-modbus'
        USE_DB = '-redis'
    }

    stages {
        stage ('Run Test on amd64') {
            environment {
                ARCH = 'x86_64'
                TAF_COMMON_IMAGE = 'nexus3.edgexfoundry.org:10003/docker-edgex-taf-common:latest'
                COMPOSE_IMAGE = 'nexus3.edgexfoundry.org:10003/edgex-devops/edgex-compose:latest'
            }
            stages {
                stage('amd64-redis'){
                    environment {
                        SECURITY_SERVICE_NEEDED = false
                    }
                    steps {
                        script {
                            startTest()
                        }
                    }
                }
                stage('amd64-redis-security'){
                    environment {
                        SECURITY_SERVICE_NEEDED = true
                    }
                    steps {
                        script {
                            startTest()
                        }
                    }
                }
            }
        }

        stage ('Publish Robotframework Report...') {
            steps{
                script {
                    catchError { unstash "security-report" }
                    catchError { unstash "report" }

                    dir ('TAF/testArtifacts/reports/merged-report/') {
                        LOGFILES= sh (
                            script: 'ls *log.html | sed ":a;N;s/\\n/,/g;ta"',
                            returnStdout: true
                        )
                    }
                }

                publishHTML(
                    target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'TAF/testArtifacts/reports/merged-report',
                        reportFiles: "${LOGFILES}",
                        reportName: 'Functional Test Reports']
                )
                junit 'TAF/testArtifacts/reports/merged-report/**.xml'
            }
        }
    }

    post {
        cleanup {
            sh "docker run --rm --network host -v /home/${USER}/.docker/config.json:/root/.docker/config.json \
                -v ${env.WORKSPACE}:${env.WORKSPACE} -w ${env.WORKSPACE}/TAF/testArtifacts/reports \
                --entrypoint rm nexus3.edgexfoundry.org:10003/docker-edgex-taf-common:latest \
                -rf ${env.WORKSPACE}/*"

            script {
                try {
                    sh 'docker stop $(docker ps -aq)'
                } catch (e) {
                    echo "Clean up error!"
                } finally {
                    sh 'docker system prune -f -a'
                    sh 'docker volume prune -f'
                }
            }
        }
    }
}

def startTest() {
    catchError {
        timeout(time: 1, unit: 'HOURS') {
            def rootDir = pwd()
            def runTestScripts = load "${rootDir}/runFunctionalTest.groovy"
            runTestScripts.main()
        }
    }
}
