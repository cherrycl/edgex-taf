#!/bin/sh

. "$(dirname "$0")/config.env"

## Retrieve Org ID
INFLUX_ORG_ID=$(curl -H "Authorization: Token ${INFLUX_INIT_TOKEN}" \
	             -H 'Content-type: application/json' \
                     -s http://${REPORT_SERVER_IP}:8086/api/v2/orgs \
		     | jq -r ".orgs|.[]|.id")

## Post a new auth to get token
RESPONSE=$(curl --request POST \
  http://${REPORT_SERVER_IP}:8086/api/v2/authorizations \
  -H "Authorization: Token ${INFLUX_INIT_TOKEN}" \
  -H 'Content-type: application/json' \
  --data '{
  "status": "active",
  "description": "iot-center-device",
  "orgID": "'"${INFLUX_ORG_ID}"'",
  "permissions": [
    {
      "action": "read",
      "resource": {
        "orgID": "'"${INFLUX_ORG_ID}"'",
        "type": "authorizations"
      }
    },
    {
      "action": "read",
      "resource": {
        "orgID": "'"${INFLUX_ORG_ID}"'",
        "type": "buckets"
      }
    },
    {
      "action": "write",
      "resource": {
        "orgID": "'"${INFLUX_ORG_ID}"'",
        "type": "buckets",
        "name": "iot-center" 
      }
    }
  ]
}')


TOKEN=$(echo $RESPONSE | jq -r '.token')

## Replace Variables in telegraf configuration file
sed -i "s/INFLUXDB_HOST/${REPORT_SERVER_IP}/g" telegraf.conf
sed -i "s/INFLUXDB_TOKEN/${TOKEN}/g" telegraf.conf
