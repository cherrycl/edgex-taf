#!/usr/bin/env python3

import influxdb_client
import matplotlib.pyplot as plt
import seaborn as sns
import sys

token = sys.argv[1]
org = "my-org"
bucket = "my-bucket"
url="http://localhost:8086"

# Retrieve data from influxdb
client = influxdb_client.InfluxDBClient(
    url=url,
    token=token,
    org=org
)

cpu_metrics = "from(bucket:\"" + bucket + "\")\
            |> range(start: -6h)\
            |> filter(fn:(r) => r._measurement == \"docker_container_cpu\")\
            |> filter(fn:(r) => r._field == \"usage_percent\")\
            |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)\
            |> keep(columns: [\"container_name\", \"_value\", \"_time\"])\
            |> pivot(rowKey:[\"_time\"], columnKey: [\"container_name\"], valueColumn: \"_value\")"

mem_metrics = "from(bucket:\"" + bucket + "\")\
            |> range(start: -6h)\
            |> filter(fn:(r) => r._measurement == \"docker_container_mem\")\
            |> filter(fn:(r) => r._field == \"usage\")\
            |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)\
            |> map(fn:(r) => ({r with _value: r._value / 1024.0 / 1024.0}))\
            |> keep(columns: [\"container_name\", \"_value\", \"_time\"])\
            |> pivot(rowKey:[\"_time\"], columnKey: [\"container_name\"], valueColumn: \"_value\")"

cpu_result = client.query_api().query_data_frame(cpu_metrics)
mem_result = client.query_api().query_data_frame(mem_metrics)
cpu_result.set_index('_time', inplace=True)
mem_result.set_index('_time', inplace=True)

# Generate chart
fig, axes = plt.subplots(2, 1, figsize=(13,10), layout='constrained')

cpu_chart=sns.lineplot(data=cpu_result[['device-modbus', 'app-logs-1', 'app-logs-2', 'core-command', 'core-metadata', 'core-keeper', 'redis', 'mqtt-broker']], ax=axes[0])
mem_chart=sns.lineplot(data=mem_result[['device-modbus', 'app-logs-1', 'app-logs-2', 'core-command', 'core-metadata', 'core-keeper', 'redis', 'mqtt-broker']], ax=axes[1])

sns.move_legend(cpu_chart, "upper left", bbox_to_anchor=(1, 1), title='Service Name')
mem_chart.get_legend().set_visible(False)

axes[0].set_title('CPU Usage')
axes[0].set_xlabel('datetime')
axes[0].set_ylabel('(%)')

axes[1].set_title('Memory Usage')
axes[1].set_xlabel('datetime')
axes[1].set_ylabel('(MiB)')

plt.savefig('performance-report.png')
