#!/bin/sh

TEST_STRATEGY=${1:-}
APPSERVICE=${2:-}
CONFIG_DIR=/custom-config

if [ "$TEST_STRATEGY" = "PerformanceMetrics" ]; then
  docker run --rm -v ${WORK_DIR}:${WORK_DIR}:rw,z -w ${WORK_DIR} -v /var/run/docker.sock:/var/run/docker.sock \
          --env WORK_DIR=${WORK_DIR} --env PROFILE=${PROFILE} --security-opt label:disable \
          --env-file ${WORK_DIR}/TAF/utils/scripts/docker/common-taf.env ${COMPOSE_IMAGE} docker compose \
          -f "${WORK_DIR}/TAF/utils/scripts/docker/docker-compose${APPSERVICE}.yml" up -d
else
  docker run --rm -v ${WORK_DIR}:${WORK_DIR}:rw,z -w ${WORK_DIR} -v /var/run/docker.sock:/var/run/docker.sock \
          --env-file ${WORK_DIR}/TAF/utils/scripts/docker/common-taf.env \
          --add-host=host.docker.internal:host-gateway \
          --env WORK_DIR=${WORK_DIR} --env CONFIG_DIR=${CONFIG_DIR} --security-opt label:disable ${COMPOSE_IMAGE} \
          docker compose -f "${WORK_DIR}/TAF/utils/scripts/docker/docker-compose.yml" up -d
  echo "================================="
  docker logs edgex-core-keeper
  docker logs edgex-core-data
fi

# Waiting for all services startup
sleep 5

if [ "$SECURITY_SERVICE_NEEDED" = "true" ]; then
  for i in $(seq 1 12);
  do
    echo "Waiting for proxy setup is ready. Loop sleep times:${i}"
    result=$(docker logs edgex-proxy-auth | grep "Service started in:")
    if [ -z "$result" ]; then
      sleep 5
    else
      echo "Proxy Setup is ready."
      break
    fi
  done
fi
