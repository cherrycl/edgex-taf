#!/bin/bash

. "$(dirname "$0")/config.env"

# Generate Report
INFLUXDB_TOKEN=$(grep -r token telegraf.conf| awk '{print $3}' | sed 's/\"//g')
python3 generate-report.py ${INFLUXDB_TOKEN} ${TIME_NUMBER} ${TIME_UNIT} ${REPORT_SERVER_IP}

FILE="./report*.png"
if [ -f "$FILE" ]; then
  # Shutdown Services
  sh performance-setup.sh shutdown
fi
