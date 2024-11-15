#!/bin/bash

OPTION=${1:-}  # Options: deploy, shutdown
MACHINE=${2:-}  # Options: edgex, simulator, report_server
SECURITY=${3:-}  # Options: true, false

. "$(dirname "$0")/config.env"

run_compose() {
  echo "Run compose command with arguments: $@"

  docker run --rm \
        -v ${HOME}/.docker/config.json:/root/.docker/config.json \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v ${PWD}:${PWD} -w ${PWD} -e WORK_DIR=${PWD} \
        --security-opt label:disable docker:26.0.1 docker compose "$@"
}

if [ "${OPTION}" = "deploy" ]; then
  if [ "${MACHINE}" = "edgex" ]; then
    sh influx_grafana_request.sh

    sh sync-compose-file.sh ${SECURITY}

    # Generate app-service configuration files
    mkdir -p app_conf simulators/devices
    SIMULATOR_PORT=5020  # Define the first simulator default port

    for n in $(seq 1 ${APP_SERVICE_COUNT})
    do
      # Update app-service compose file
      cp app-service.yml app_conf/app-sample-${n}.yml
      sed -i "s/INDEX/${n}/g" app_conf/app-sample-${n}.yml
      sed -i "/services:/ r app_conf/app-sample-${n}.yml" docker-compose-main.yml

      # Update app-service configuration YAML file
      mkdir -p app_conf/mqtt-sample-${n}
      cp app-template.yaml app_conf/mqtt-sample-${n}/configuration.yaml
      sed -i "s/PROFILE_NAME/device-sim-${n}/g" app_conf/mqtt-sample-${n}/configuration.yaml
      sed -i "s/BROKER_ADDRESS/tcp:\/\/${REPORT_SERVER_IP}:${BROKER_PORT}/g" app_conf/mqtt-sample-${n}/configuration.yaml
      sed -i "s/APP_INDEX/${n}/g" app_conf/mqtt-sample-${n}/configuration.yaml

      # Generate devices.yaml
      for i in $(seq 1 ${DEVICE_COUNT})
      do
        cat device-template.yaml >> simulators/devices/device-sim-${n}.yaml
        sed -i "s/DEVICE_INDEX/${i}/g" simulators/devices/device-sim-${n}.yaml
      done
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
    rm -rf app_conf simulators/devices

  elif [ "${MACHINE}" = "simulator" ]; then
    run_compose -f docker-compose-simulators.yml down -v

  elif [ "${MACHINE}" = "report_server" ]; then
    run_compose -f docker-compose-report.yml down -v
  fi
else
    echo "OPTION values: deploy, shutdown"
fi
