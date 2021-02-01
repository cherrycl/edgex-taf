#!/usr/bin/env groovy

def main() {
    def USE_SECURITY = ''
    def SET_SECURITY = ''

    stage ('Pre-defined') {
        script {
            if ("${SECURITY_SERVICE_NEEDED}" == 'true') {
                USE_SECURITY = 'security-'
                SET_SECURITY = '-security-'
            }
        }
    }
    stage ("Get compose file from github") {
        dir ("TAF/utils/scripts/docker") {
            sh "sh get-compose-file.sh ${USE_DB} ${ARCH} ${SET_SECURITY}"
        }
    }
    stage ("${USE_SECURITY} Deploy EdgeX Services") {
        sh "docker run --rm --network host -v ${env.WORKSPACE}:${env.WORKSPACE}:z -w ${env.WORKSPACE} \
                -e COMPOSE_IMAGE=${COMPOSE_IMAGE} -e SECURITY_SERVICE_NEEDED=${SECURITY_SERVICE_NEEDED} \
                -e USE_DB=${USE_DB} --security-opt label:disable \
                -v /var/run/docker.sock:/var/run/docker.sock ${TAF_COMMON_IMAGE} \
                --exclude Skipped --include deploy-base-service -u deploy.robot -p default"

        dir ("TAF/testArtifacts/reports/${USE_SECURITY}report") {
            sh "cp ../edgex/log.html ${USE_SECURITY}deploy-edgex-log.html"
            sh "cp ../edgex/report.xml ${USE_SECURITY}deploy-edgex-report.xml"
        }
    }
    stage ("${USE_SECURITY} Run Tests") {
        def PROFILES = "${params.PROFILE}".split()

        for (x in PROFILES) {
            def profile = x
            echo '===== Deploy Device Service ====='
            sh "docker run --rm --network host -v ${env.WORKSPACE}:${env.WORKSPACE}:z -w ${env.WORKSPACE} \
                    -e COMPOSE_IMAGE=${COMPOSE_IMAGE} -e ARCH=${ARCH} --security-opt label:disable \
                    -v /var/run/docker.sock:/var/run/docker.sock ${TAF_COMMON_IMAGE} \
                    --exclude Skipped --include deploy-device-service -u deploy.robot -p device-virtual"

            dir ("TAF/testArtifacts/reports/${USE_SECURITY}report") {
                sh "cp ../edgex/log.html ${USE_SECURITY}deploy-device-virtual-log.html"
                sh "cp ../edgex/report.xml ${USE_SECURITY}deploy-device-virtual-report.xml"
            }
            
            sh "docker run --rm --network host -v ${env.WORKSPACE}:${env.WORKSPACE}:z -w ${env.WORKSPACE} \
                    -e COMPOSE_IMAGE=${COMPOSE_IMAGE} -e SECURITY_SERVICE_NEEDED=${SECURITY_SERVICE_NEEDED} \
                    -e ARCH=${ARCH} --security-opt label:disable \
                    -v /var/run/docker.sock:/var/run/docker.sock ${TAF_COMMON_IMAGE} \
                    --exclude Skipped -u functionalTest/device-service/common -p device-virtual"
            dir ("TAF/testArtifacts/reports/${USE_SECURITY}report") {
                sh "cp ../edgex/log.html ${USE_SECURITY}device-virtual-common-log.html"
                sh "cp ../edgex/report.xml ${USE_SECURITY}device-virtual-common-report.xml"
            }

            echo '===== Shutdown device-service ====='
            sh "docker run --rm --network host -v ${env.WORKSPACE}:${env.WORKSPACE}:z -w ${env.WORKSPACE} \
                    -e COMPOSE_IMAGE=${COMPOSE_IMAGE} -e ARCH=${ARCH} --security-opt label:disable \
                    -v /var/run/docker.sock:/var/run/docker.sock ${TAF_COMMON_IMAGE} \
                    --exclude Skipped --include shutdown-device-service -u shutdown.robot -p device-virtual"
            dir ("TAF/testArtifacts/reports/${USE_SECURITY}report") {
                sh "cp ../edgex/log.html ${USE_SECURITY}shutdown-device-virtual-log.html"
                sh "cp ../edgex/report.xml ${USE_SECURITY}shutdown-device-virtual-report.xml"
            } 
        }
        
        stage ("Run V2 API Tests"){
            echo "===== Run V2 API Tests ====="
            sh "docker run --rm --network host -v ${env.WORKSPACE}:${env.WORKSPACE}:z -w ${env.WORKSPACE} \
                    -e COMPOSE_IMAGE=${COMPOSE_IMAGE} -e SECURITY_SERVICE_NEEDED=${SECURITY_SERVICE_NEEDED} \
                    -e ARCH=${ARCH} --security-opt label:disable \
                    -v /var/run/docker.sock:/var/run/docker.sock ${TAF_COMMON_IMAGE} \
                    --exclude Skipped --include v2-api -u functionalTest/V2-API -p default"
            dir ("TAF/testArtifacts/reports/${USE_SECURITY}report") {
                sh "cp ../edgex/log.html ${USE_SECURITY}v2-api-log.html"
                sh "cp ../edgex/report.xml ${USE_SECURITY}v2-api-report.xml"
            }
        }
    }
    stage ("Shutdown EdgeX - ${ARCH}${USE_DB}${USE_SECURITY}") {
        sh "docker run --rm --network host -v ${env.WORKSPACE}:${env.WORKSPACE}:z -w ${env.WORKSPACE} \
                -e COMPOSE_IMAGE=${COMPOSE_IMAGE} --security-opt label:disable \
                -v /var/run/docker.sock:/var/run/docker.sock ${TAF_COMMON_IMAGE} \
                --exclude Skipped --include shutdown-edgex -u shutdown.robot -p default"

        dir ("TAF/testArtifacts/reports/${USE_SECURITY}report") {
            sh "cp ../edgex/log.html ${USE_SECURITY}shutdown-edgex-log.html"
            sh "cp ../edgex/report.xml ${USE_SECURITY}shutdown-edgex-report.xml"
        }
    }
    stage ("${USE_SECURITY} Merge Reports") {
        sh "docker run --rm --network host -v ${env.WORKSPACE}:${env.WORKSPACE}:z -w ${env.WORKSPACE} \
                -e COMPOSE_IMAGE=${COMPOSE_IMAGE} ${TAF_COMMON_IMAGE} \
                rebot --inputdir TAF/testArtifacts/reports/${USE_SECURITY}report \
                --outputdir TAF/testArtifacts/reports/${USE_SECURITY}merge-report"

        dir ("TAF/testArtifacts/reports/${USE_SECURITY}merge-report") {
            // Check if the merged-report folder exists
            def mergeExist = sh (
                script: 'ls ../ | grep merged-report',
                returnStatus: true
            )
            if (mergeExist != 0) {
                sh 'mkdir ../merged-report'
            }

            //Copy log file to merged-report folder
            sh "cp log.html ../merged-report/${USE_SECURITY}log.html"
            sh "cp result.xml ../merged-report/${USE_SECURITY}report.xml"
        }

        stash name: "${USE_SECURITY}report", includes: "TAF/testArtifacts/reports/merged-report/*", allowEmpty: true
    }
}
return this
