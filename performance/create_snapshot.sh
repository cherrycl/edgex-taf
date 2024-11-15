#!/bin/sh

. "$(dirname "$0")/config.env"

RUNNING_SERVICES=$(docker ps --format {{.Names}} | grep -v telegraf | grep -v device-sim|grep -v grafana|grep -v influxdb)
AVAILABLE_SERVICES=$(echo $RUNNING_SERVICES| sed 's/ /","/g')

CURRENT_TIMESTAMP=$(date +"%Y%m%d%H%M%S")
TO_TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S")
FROM_TIMESTAMP=$(date -d "-${TIME_RANGE}" +'%Y-%m-%dT%H:%M:%S')

## Create Grafana Snapshot
RESPONSE=$(curl --request POST \
  http://${REPORT_SERVER_IP}:3000/api/snapshots \
  -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
  -H 'Content-type: application/json' \
  --data '{
  "name": "'"performance-${CURRENT_TIMESTAMP}"'",
  "dashboard": {
    "__inputs": [
      {
        "name": "DS_INFLUXDB",
        "label": "InfluxDB",
        "description": "v2.x",
        "type": "datasource",
        "pluginId": "influxdb",
        "pluginName": "InfluxDB"
      }
    ],
    "__elements": {},
    "__requires": [
      {
        "type": "grafana",
        "id": "grafana",
        "name": "Grafana",
        "version": "9.1.5"
      },
      {
        "type": "datasource",
        "id": "influxdb",
        "name": "InfluxDB",
        "version": "1.0.0"
      },
      {
        "type": "panel",
        "id": "stat",
        "name": "Stat",
        "version": ""
      },
      {
        "type": "panel",
        "id": "timeseries",
        "name": "Time series",
        "version": ""
      }
    ],
    "annotations": {
      "list": [
        {
          "builtIn": 1,
          "datasource": {
            "type": "grafana",
            "uid": "-- Grafana --"
          },
          "enable": true,
          "hide": true,
          "iconColor": "rgba(0, 211, 255, 1)",
          "name": "Annotations & Alerts",
          "target": {
            "limit": 100,
            "matchAny": false,
            "tags": [],
            "type": "dashboard"
          },
          "type": "dashboard"
        }
      ]
    },
    "editable": false,
    "fiscalYearStartMonth": 0,
    "graphTooltip": 0,
    "id": null,
    "links": [],
    "liveNow": false,
    "panels": [
      {
        "datasource": {
          "type": "influxdb",
          "uid": "'"${GRAFANA_DS_NAME}"'"
        },
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "none"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 5,
          "w": 3,
          "x": 0,
          "y": 0
        },
        "id": 8,
        "options": {
          "colorMode": "none",
          "graphMode": "none",
          "justifyMode": "auto",
          "orientation": "auto",
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "textMode": "auto"
        },
        "pluginVersion": "9.1.5",
        "targets": [
          {
            "datasource": {
              "type": "influxdb",
              "uid": "'"${GRAFANA_DS_NAME}"'"
            },
            "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"docker\")\n  |> filter(fn: (r) => r[\"_field\"] == \"n_cpus\")\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
            "refId": "A"
          }
        ],
        "title": "Total Cpus",
        "type": "stat"
      },
      {
        "datasource": {
          "type": "influxdb",
          "uid": "'"${GRAFANA_DS_NAME}"'"
        },
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "decbytes"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 5,
          "w": 3,
          "x": 3,
          "y": 0
        },
        "id": 7,
        "options": {
          "colorMode": "none",
          "graphMode": "none",
          "justifyMode": "auto",
          "orientation": "auto",
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "textMode": "auto"
        },
        "pluginVersion": "9.1.5",
        "targets": [
          {
            "datasource": {
              "type": "influxdb",
              "uid": "'"${GRAFANA_DS_NAME}"'"
            },
            "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"docker\")\n  |> filter(fn: (r) => r[\"_field\"] == \"memory_total\")\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
            "refId": "A"
          }
        ],
        "title": "Total Memory",
        "type": "stat"
      },
      {
        "datasource": {
          "type": "influxdb",
          "uid": "'"${GRAFANA_DS_NAME}"'"
        },
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "red",
                  "value": 80
                }
              ]
            }
          },
          "overrides": []
        },
        "gridPos": {
          "h": 5,
          "w": 3,
          "x": 6,
          "y": 0
        },
        "id": 4,
        "options": {
          "colorMode": "value",
          "graphMode": "none",
          "justifyMode": "auto",
          "orientation": "auto",
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "textMode": "auto"
        },
        "pluginVersion": "9.1.5",
        "targets": [
          {
            "datasource": {
              "type": "influxdb",
              "uid": "'"${GRAFANA_DS_NAME}"'"
            },
            "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"docker\")\n  |> filter(fn: (r) => r[\"_field\"] == \"n_containers_running\")\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
            "refId": "A"
          }
        ],
        "title": "Running Containers",
        "type": "stat"
      },
      {
        "datasource": {
          "type": "influxdb",
          "uid": "'"${GRAFANA_DS_NAME}"'"
        },
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "orange",
                  "value": null
                }
              ]
            }
          },
          "overrides": []
        },
        "gridPos": {
          "h": 5,
          "w": 3,
          "x": 9,
          "y": 0
        },
        "id": 5,
        "options": {
          "colorMode": "value",
          "graphMode": "none",
          "justifyMode": "auto",
          "orientation": "auto",
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "textMode": "auto"
        },
        "pluginVersion": "9.1.5",
        "targets": [
          {
            "datasource": {
              "type": "influxdb",
              "uid": "'"${GRAFANA_DS_NAME}"'"
            },
            "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"docker\")\n  |> filter(fn: (r) => r[\"_field\"] == \"n_containers_paused\")\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
            "refId": "A"
          }
        ],
        "title": "Paused Containers",
        "type": "stat"
      },
      {
        "datasource": {
          "type": "influxdb",
          "uid": "'"${GRAFANA_DS_NAME}"'"
        },
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "red",
                  "value": null
                }
              ]
            }
          },
          "overrides": []
        },
        "gridPos": {
          "h": 5,
          "w": 3,
          "x": 12,
          "y": 0
        },
        "id": 6,
        "options": {
          "colorMode": "value",
          "graphMode": "none",
          "justifyMode": "auto",
          "orientation": "auto",
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "text": {},
          "textMode": "auto"
        },
        "pluginVersion": "9.1.5",
        "targets": [
          {
            "datasource": {
              "type": "influxdb",
              "uid": "'"${GRAFANA_DS_NAME}"'"
            },
            "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"docker\")\n  |> filter(fn: (r) => r[\"_field\"] == \"n_containers_stopped\")\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
            "refId": "A"
          }
        ],
        "title": "Paused Containers",
        "type": "stat"
      },
      {
        "datasource": {
          "type": "influxdb",
          "uid": "'"${GRAFANA_DS_NAME}"'"
        },
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "none"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 5,
          "w": 3,
          "x": 15,
          "y": 0
        },
        "id": 11,
        "options": {
          "colorMode": "none",
          "graphMode": "none",
          "justifyMode": "auto",
          "orientation": "auto",
          "reduceOptions": {
            "calcs": [
              "lastNotNull"
            ],
            "fields": "",
            "values": false
          },
          "textMode": "auto"
        },
        "pluginVersion": "9.1.5",
        "targets": [
          {
            "datasource": {
              "type": "influxdb",
              "uid": "'"${GRAFANA_DS_NAME}"'"
            },
            "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"docker\")\n  |> filter(fn: (r) => r[\"_field\"] == \"n_images\")\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
            "refId": "A"
          }
        ],
        "title": "Images",
        "type": "stat"
      },
      {
        "datasource": {
          "type": "influxdb",
          "uid": "'"${GRAFANA_DS_NAME}"'"
        },
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisCenteredZero": false,
              "axisColorMode": "text",
              "axisLabel": "",
              "axisPlacement": "auto",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 0,
              "gradientMode": "none",
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "viz": false
              },
              "lineInterpolation": "linear",
              "lineWidth": 1,
              "pointSize": 5,
              "scaleDistribution": {
                "type": "linear"
              },
              "showPoints": "auto",
              "spanNulls": false,
              "stacking": {
                "group": "A",
                "mode": "none"
              },
              "thresholdsStyle": {
                "mode": "off"
              }
            },
            "displayName": "${__field.labels.container_name}",
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "red",
                  "value": 80
                }
              ]
            },
            "unit": "percent"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 10,
          "w": 24,
          "x": 0,
          "y": 5
        },
        "id": 2,
        "options": {
          "legend": {
            "calcs": [],
            "displayMode": "list",
            "placement": "bottom",
            "showLegend": true
          },
          "tooltip": {
            "mode": "single",
            "sort": "none"
          }
        },
        "targets": [
          {
            "datasource": {
              "type": "influxdb",
              "uid": "'"${GRAFANA_DS_NAME}"'"
            },
            "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"docker_container_cpu\")\n  |> filter(fn: (r) => r[\"_field\"] == \"usage_percent\")\n  |> filter(fn: (r) => r[\"container_name\"] =~ /${container:regex}/)\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
            "refId": "A"
          }
        ],
        "title": "Cpu Usage",
        "type": "timeseries"
      },
      {
        "datasource": {
          "type": "influxdb",
          "uid": "'"${GRAFANA_DS_NAME}"'"
        },
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "axisCenteredZero": false,
              "axisColorMode": "text",
              "axisLabel": "",
              "axisPlacement": "auto",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 0,
              "gradientMode": "none",
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "viz": false
              },
              "lineInterpolation": "linear",
              "lineWidth": 1,
              "pointSize": 5,
              "scaleDistribution": {
                "type": "linear"
              },
              "showPoints": "auto",
              "spanNulls": false,
              "stacking": {
                "group": "A",
                "mode": "none"
              },
              "thresholdsStyle": {
                "mode": "off"
              }
            },
            "displayName": "${__field.labels.container_name}",
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "red",
                  "value": 80
                }
              ]
            },
            "unit": "bytes"
          },
          "overrides": []
        },
        "gridPos": {
          "h": 12,
          "w": 24,
          "x": 0,
          "y": 15
        },
        "id": 10,
        "options": {
          "legend": {
            "calcs": [],
            "displayMode": "list",
            "placement": "bottom",
            "showLegend": true
          },
          "tooltip": {
            "mode": "single",
            "sort": "none"
          }
        },
        "targets": [
          {
            "datasource": {
              "type": "influxdb",
              "uid": "'"${GRAFANA_DS_NAME}"'"
            },
            "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"docker_container_mem\")\n  |> filter(fn: (r) => r[\"_field\"] == \"usage\")\n  |> filter(fn: (r) => r[\"container_name\"] =~ /${container:regex}/)\n  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n  |> yield(name: \"mean\")",
            "refId": "A"
          }
        ],
        "title": "Memory Usage",
        "type": "timeseries"
      }
    ],
    "schemaVersion": 37,
    "style": "dark",
    "tags": [
      "docker",
      "influxdb2.0"
    ],
    "templating": {
      "list": [
        {
          "current": {},
          "datasource": {
            "type": "influxdb",
            "uid": "'"${GRAFANA_DS_NAME}"'"
          },
          "definition": "buckets()",
          "hide": 0,
          "includeAll": false,
          "multi": false,
          "name": "bucket",
          "options": [],
          "query": "buckets()",
          "refresh": 1,
          "regex": "",
          "skipUrlSync": false,
          "sort": 0,
          "type": "query"
        },
        {
          "current": {
            "selected": true,
            "text": ["'"${AVAILABLE_SERVICES}"'"],
            "value": ["'"${AVAILABLE_SERVICES}"'"]
          },
          "datasource": {
            "type": "influxdb",
            "uid": "'"${GRAFANA_DS_NAME}"'"
          },
          "definition": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"docker_container_cpu\")\n  |> keyValues(keyColumns: [\"container_name\"])\n  |> group()\n  |> keep(columns: [\"container_name\"])\n  |> distinct(column: \"container_name\")",
          "hide": 0,
          "includeAll": false,
          "multi": true,
          "name": "container",
          "options": [],
          "query": "from(bucket: \"${bucket}\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"docker_container_cpu\")\n  |> keyValues(keyColumns: [\"container_name\"])\n  |> group()\n  |> keep(columns: [\"container_name\"])\n  |> distinct(column: \"container_name\")",
          "refresh": 1,
          "regex": "",
          "skipUrlSync": false,
          "sort": 0,
          "type": "query"
        }
      ]
    },
    "time": {
      "from": "'"${FROM_TIMESTAMP}"'",
      "to": "'"${TO_TIMESTAMP}"'"
    },
    "timepicker": {},
    "timezone": "",
    "title": "InfluxDB 2.x Telegraf Docker Dashboard",
    "version": 7,
    "weekStart": "",
    "gnetId": 17020,
    "description": "Basic docker dashboard for InfluxDB 2.x and telegraf collector."
  }
}')

DELETE_KEY=$(echo $RESPONSE | jq -r ".deleteKey")
DELETE_URL=$(echo $RESPONSE | jq -r ".deleteUrl")
SNAPSHOT_KEY=$(echo $RESPONSE | jq -r ".key")
SNAPSHOT_URL=$(echo $RESPONSE | jq -r ".url")

echo "Snapshot URL: ${SNAPSHOT_URL}"
echo "Snapshot Key: ${SNAPSHOT_KEY}"
echo "Delete URL: ${DELETE_URL}"
echo "Delete Key: ${DELETE_KEY}"
