#!/bin/sh
# set default values
USE_ARCH=${1:-x86_64}
USE_SECURITY=${2:--}
USE_SHA1=${3:-main}

# # x86_64 or arm64
[ "$USE_ARCH" = "arm64" ] && USE_ARM64="-arm64"
[ "$USE_SECURITY" = "-security-" ] && SECURITY_SERVICE_NEEDED="true"

TAF_COMMON_IMAGE=nexus3.edgexfoundry.org:10003/edgex-taf-common${USE_ARM64}:latest
COMPOSE_IMAGE=docker:26.0.1


# Pull edgex images
sh get-compose-file-perfermance.sh ${USE_ARCH} ${USE_SECURITY} ${USE_SHA1}

# Pull images
docker run --rm -v ${WORK_DIR}:${WORK_DIR}:rw,z -w ${WORK_DIR} -v ${DOCKER_SOCKET_PATH}:/var/run/docker.sock \
        --env WORK_DIR=${WORK_DIR} --security-opt label:disable \
        ${COMPOSE_IMAGE} docker compose -f "${WORK_DIR}/TAF/utils/scripts/docker/docker-compose.yml" pull
sleep 5

# Run scripts to collect performance metrics and generate reports
docker run --rm --network host --privileged -v ${WORK_DIR}:${WORK_DIR}:z -w ${WORK_DIR} -e ARCH=${USE_ARCH} \
       -v ${DOCKER_SOCKET_PATH}:/var/run/docker.sock -e SECURITY_SERVICE_NEEDED=${SECURITY_SERVICE_NEEDED} \
       --env-file ${WORK_DIR}/TAF/utils/scripts/docker/common-taf.env \
       -e COMPOSE_IMAGE=${COMPOSE_IMAGE} ${TAF_COMMON_IMAGE} \
       --exclude Skipped -u performanceTest/performance-metrics-collection --profile performance-metrics

