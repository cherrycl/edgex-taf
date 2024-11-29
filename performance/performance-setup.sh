#!/bin/bash

OPTION=${1:-}  # Options: deploy, shutdown
MACHINE=${2:-}  # Options: edgex, simulator, report_server
SECURITY=${3:-false}  # Options: true, false

. "$(dirname "$0")/config.env"

# Get HOST_DOCKER_GROUP_ID for telegraf service
DOCKER_ID=$(docker run --rm -v /etc/group:/etc/host/group --entrypoint cat \
       docker:26.0.1 /etc/host/group | grep docker)
HOST_DOCKER_GROUP_ID=$(echo $DOCKER_ID | cut -d : -f 3)

# x86_64 or arm64
UN=$(uname -m)
[ "$UN" = "aarch64" ] && USE_ARM64="-arm64"

run_compose() {
  echo "Run compose command with arguments: $@"

  docker run --rm \
        -v ${HOME}/.docker/config.json:/root/.docker/config.json -v ${PWD}:${PWD} -w ${PWD} \
        -v /var/run/docker.sock:/var/run/docker.sock -e USE_ARM64=${USE_ARM64} -e WORK_DIR=${PWD} \
        --security-opt label:disable docker:26.0.1 docker compose  --env-file compose.env -p edgex "$@"
}

if [ "${OPTION}" = "deploy" ]; then
  if [ "${MACHINE}" = "edgex" ]; then
    sh influx_grafana_request.sh

    sh sync-compose-file.sh ${SECURITY}
    # Removed unused service
    unused_services="device-virtual device-rest app-rules-engine app-mqtt-export taf-mqtt-broker kuiper ui-go"
    for service in $unused_services; do
      sed -i "/^\ \ ${service}:/,/^  [a-z].*:$/{//!d}; /^\ \ ${service}:/d" docker-compose.yml
    done

    if [ ! -d app_conf ] || [ ! -d  simulators/devices ]; then
      # Generate app-service configuration files
      mkdir -p app_conf simulators/devices
      SIMULATOR_PORT=5020  # Define the first simulator default port

      for n in $(seq 1 ${APP_SERVICE_COUNT})
      do
        # Update app-service compose file
        cp app-service.yml app_conf/app-sample_${n}.yml
        sed -i "s/INDEX/${n}/g" app_conf/app-sample_${n}.yml
        sed -i "/services:/ r app_conf/app-sample_${n}.yml" docker-compose-main.yml

        # Update app-service configuration YAML file
        mkdir -p app_conf/mqtt-sample_${n}
        cp app-template.yaml app_conf/mqtt-sample_${n}/configuration.yaml
        sed -i "s/PROFILE_NAME/device-sim-${n}/g" app_conf/mqtt-sample_${n}/configuration.yaml
        sed -i "s/BROKER_ADDRESS/tcp:\/\/${REPORT_SERVER_IP}:${BROKER_PORT}/g" app_conf/mqtt-sample_${n}/configuration.yaml
        sed -i "s/APP_INDEX/${n}/g" app_conf/mqtt-sample_${n}/configuration.yaml

        # Generate devices.yaml
        for i in $(seq 1 ${DEVICE_COUNT})
        do
          cat device-template.yaml >> simulators/devices/device-sim-${n}.yaml
          sed -i "s/DEVICE_INDEX/${i}/g" simulators/devices/device-sim-${n}.yaml
        done
        sed -i '1 i\deviceList:' simulators/devices/device-sim-${n}.yaml
        sed -i "s/PROFILE_NAME/device-sim-${n}/g" simulators/devices/device-sim-${n}.yaml
        sed -i "s/SIMULATOR_IP/${SIMULATOR_IP}/g" simulators/devices/device-sim-${n}.yaml
        sed -i "s/SIMULATOR_PORT/${SIMULATOR_PORT}/g" simulators/devices/device-sim-${n}.yaml
        sed -i "s/SIMULATOR_UNIT/${n}/g" simulators/devices/device-sim-${n}.yaml

        # Since port number of simulators is sequence, increase 1 when creating a new app-service profile
        SIMULATOR_PORT=$((SIMULATOR_PORT+1))
      done

      # Generate app-service configuration file path
      profiles=""
      for file in app_conf/*; do
        if [ "${profiles}" = "" ]; then
          profiles="${file}"
        else
          profiles="${profiles},${file}"
        fi
      done
    fi

    run_compose -f docker-compose.yml -f docker-compose-main.yml up -d

  elif [ "${MACHINE}" = "simulator" ]; then
    services=""
    for i in $(seq 1 ${DEVICE_COUNT})
    do
      services="${services} device-sim-${i}"
    done
    run_compose -f docker-compose-simulators.yml up -d

  elif [ "${MACHINE}" = "report_server" ]; then
    run_compose -f docker-compose-report.yml up -d
  else
    echo "MACHINE values: edgex, simulator, report_server"
  fi
  
elif [ "${OPTION}" = "shutdown" ]; then
  if [ "${MACHINE}" = "edgex" ]; then
    run_compose -f docker-compose.yml -f docker-compose-main.yml down -v

  elif [ "${MACHINE}" = "simulator" ]; then
    run_compose -f docker-compose-simulators.yml down -v

  elif [ "${MACHINE}" = "report_server" ]; then
    run_compose -f docker-compose-report.yml down -v
  elif [ "${MACHINE}" = "remove_data" ]; then
    rm -rf app_conf simulators/devices docker-compose.yml
    git stash
  fi
else
    echo "OPTION values: deploy, shutdown"
fi
