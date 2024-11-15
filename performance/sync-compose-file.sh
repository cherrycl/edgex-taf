#!/bin/bash

# x86_64 or arm64
UN=$(uname -m)
[ "$UN" = "aarch64" ] && USE_ARM64="-arm64"

# security or no security
SECURITY=$1
[ "$SECURITY" = "false" ] && USE_NO_SECURITY="-no-secty"

# Use specified commit or main
USE_SHA1=${2:-main}

# Use TAF compose file
TAF=${3:--taf}
TAF_PERF=${4:--perf}

# Handle TAF specific compose files
[ "$TAF" = "-taf" ] && TAF_SUB_FOLDER="/taf"

NIGHTLY_BUILD_URL="https://raw.githubusercontent.com/edgexfoundry/edgex-compose/${USE_SHA1}${TAF_SUB_FOLDER}"

COMPOSE_FILE="docker-compose${TAF}${TAF_PERF}${USE_NO_SECURITY}${USE_ARM64}.yml"
curl -o docker-compose.yml "${NIGHTLY_BUILD_URL}/${COMPOSE_FILE}"
