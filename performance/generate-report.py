#!/usr/bin/env python3

import influxdb_client
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import seaborn as sns
import pandas as pd
import sys
import time

# To ignore Pivot warning
import warnings
from influxdb_client.client.warnings import MissingPivotFunction

warnings.simplefilter("ignore", MissingPivotFunction)

token = sys.argv[1]
time_number = sys.argv[2]
time_unit = sys.argv[3]
influxdb_ip = sys.argv[4]
org = "my-org"
bucket = "my-bucket"
url = "http://" + influxdb_ip + ":8086"

# Retrieve data from influxdb
client = influxdb_client.InfluxDBClient(
    url=url,
    token=token,
    org=org
)

# Set Report Time Range
unit = ""
if time_unit == "minute":
    unit = "m"
elif time_unit == "hour":
    unit = "h"
elif time_unit == "day":
    unit = "d"
else:
    print("invalid time unit")

time_range = time_number + unit


## Retrieve Total CPUs / Memory
host_total_cpu_flux = "from(bucket: \"" + bucket + "\")\
         |> range(start: -1m)\
         |> filter(fn: (r) => r[\"_measurement\"] == \"docker\")\
         |> filter(fn: (r) => r[\"_field\"] == \"n_cpus\")\
         |> aggregateWindow(every: " + time_range + ", fn: mean, createEmpty: false)\
         |> keep(columns: [\"_value\"])\
         |> yield(name: \"mean\")"

host_total_mem_flux = "from(bucket: \"" + bucket + "\")\
         |> range(start: -1m)\
         |> filter(fn: (r) => r[\"_measurement\"] == \"docker\")\
         |> filter(fn: (r) => r[\"_field\"] == \"memory_total\")\
         |> aggregateWindow(every: " + time_range + ", fn: mean, createEmpty: false)\
         |> map(fn:(r) => ({r with _value: r._value / 1024.0 / 1024.0 / 1024.0}))\
         |> keep(columns: [\"_value\"])\
         |> yield(name: \"mean\")"

host_total_cpu = client.query_api().query_data_frame(host_total_cpu_flux)
host_total_mem = client.query_api().query_data_frame(host_total_mem_flux)


## Gerenate HOST CPU/Memory Usage DataFrame For LineChart
host_cpu_usage_flux = "from(bucket:\"" + bucket + "\")\
            |> range(start: -" + time_range + ")\
            |> filter(fn:(r) => r._measurement == \"cpu\")\
            |> filter(fn:(r) => r._field == \"usage_system\")\
            |> filter(fn:(r) => r.cpu == \"cpu-total\")\
            |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)\
            |> keep(columns: [\"_value\", \"_time\"])"

host_mem_usage_flux = "from(bucket:\"" + bucket + "\")\
            |> range(start: -" + time_range + ")\
            |> filter(fn:(r) => r._measurement == \"mem\")\
            |> filter(fn:(r) => r._field == \"used\")\
            |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)\
            |> keep(columns: [\"_value\", \"_time\"])"

host_cpu_usage = client.query_api().query_data_frame(host_cpu_usage_flux)
host_cpu_usage.set_index('_time', inplace=True)
host_mem_usage = client.query_api().query_data_frame(host_mem_usage_flux)
host_mem_usage.set_index('_time', inplace=True)


## Generate Container CPU/Memory Usage DataFrame For LineChart
container_cpu_usage_flux = "from(bucket:\"" + bucket + "\")\
            |> range(start: -" + time_range + ")\
            |> filter(fn:(r) => r._measurement == \"docker_container_cpu\")\
            |> filter(fn:(r) => r._field == \"usage_percent\")\
            |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)\
            |> keep(columns: [\"container_name\", \"_value\", \"_time\"])\
            |> pivot(rowKey:[\"_time\"], columnKey: [\"container_name\"], valueColumn: \"_value\")"

container_mem_usage_flux = "from(bucket:\"" + bucket + "\")\
            |> range(start: -" + time_range + ")\
            |> filter(fn:(r) => r._measurement == \"docker_container_mem\")\
            |> filter(fn:(r) => r._field == \"usage\")\
            |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)\
            |> map(fn:(r) => ({r with _value: r._value / 1024.0 / 1024.0}))\
            |> keep(columns: [\"container_name\", \"_value\", \"_time\"])\
            |> pivot(rowKey:[\"_time\"], columnKey: [\"container_name\"], valueColumn: \"_value\")"

container_cpu_usage = client.query_api().query_data_frame(container_cpu_usage_flux)
container_mem_usage = client.query_api().query_data_frame(container_mem_usage_flux)
container_cpu_usage.set_index('_time', inplace=True)
container_mem_usage.set_index('_time', inplace=True)


# Generate Container CPU/Memory Aggregation DataFrame Label
## Retrieve Service List
import subprocess

cmd = "docker ps -a --format {{.Names}}".split()
services = subprocess.run(cmd, capture_output=True, text=True)
services = services.stdout.strip().split('\n')

remove_device_sim = [name for name in services if 'device-sim' not in name]
remove_service = ['telegraf', 'influxdb', 'grafana', 'core-keeper', 'external-mqtt-broker']
service_list = [i for i in remove_device_sim if i not in remove_service]

row = {'aggregation': ['min', 'max', 'avg']}
container_cpu_agg = pd.DataFrame(row)
container_mem_agg = pd.DataFrame(row)

agg_labels = ['min', 'max', 'mean']

##  Container CPU Aggregation DataFrame
for service in service_list:
    container_cpu_agg_values = []
    for label in agg_labels:
        value = container_cpu_usage_flux + "|>" + label + "(column: \"" + service + "\")\
                    |> keep(columns: [\"" + service + "\"])\
                    |> yield(name: \"" + label + "\")"

        data = client.query_api().query_data_frame(value)
        data[service] = data[service].map('{:,.2f}%'.format)
        data.set_index('result', inplace=True)

        container_cpu_agg_values.append(data.loc[label, service])

    container_cpu_agg[service] = container_cpu_agg_values

## Container Memory Aggregation DataFrame
for service in service_list:
    container_mem_agg_values = []
    for label in agg_labels:
        value = container_mem_usage_flux + "|>min(column: \"" + service + "\")\
                |> keep(columns: [\"" + service + "\"])\
                |> yield(name: \"" + label + "\")"

        data = client.query_api().query_data_frame(value)
        data[service] = data[service].map('{:,.2f}MiB'.format)
        data.set_index('result', inplace=True)

        container_mem_agg_values.append(data.loc[label, service])

    container_mem_agg[service] = container_mem_agg_values

# Generate report chart
fig = plt.figure(figsize=(25, 40), layout='constrained')
fig.text(
    x=.05, y=0.95,
    s='Performance Report',
    ha='left',
    va='bottom',
    weight='bold',
    size=25
)

gs = fig.add_gridspec(6, 4)
ax0_0 = fig.add_subplot(gs[0, 0])  # Host Total CPU
ax1_0 = fig.add_subplot(gs[1, 0])  # Host Total Memory
ax1 = fig.add_subplot(gs[0, 1:])  # Host CPU Usage
ax2 = fig.add_subplot(gs[1, 1:])  # Host Memory Usage
ax3 = fig.add_subplot(gs[2, :])  # Container CPU Usage
ax4 = fig.add_subplot(gs[3, :])  # Container CPU Aggregation
ax5 = fig.add_subplot(gs[4, :])  # Container Memory Usage
ax6 = fig.add_subplot(gs[5, :])  # Container Memory Aggregation

## HOST Total CPU Count ##
ax0_0.set_title('Total CPU', size=16, fontweight="bold")
cpu_count = host_total_cpu['_value'].map(int)
ax0_0.annotate(cpu_count.to_string(index=False), xy=(0.5, 0.5), fontsize=50,
               ha='center', va='center',
               arrowprops=dict(facecolor='blue', shrink=0.05))
pos0 = ax0_0.get_position()
pos1 = [pos0.x0, pos0.y0 + 0.08, pos0.width, pos0.height]
ax0_0.set_position(pos1)
ax0_0.set_xticks([])
ax0_0.set_yticks([])

## HOST Total Memory ##
ax1_0.set_title('Total Memory', size=16, fontweight="bold")
mem_value = host_total_mem['_value'].map('{:,.2f}GB'.format)
ax1_0.annotate(mem_value.to_string(index=False), xy=(0.5, 0.5), fontsize=50,
               ha='center', va='center',
               arrowprops=dict(facecolor='blue', shrink=0.05))
ax1_0.set_xticks([])
ax1_0.set_yticks([])

## HOST CPU ##
ax1.set_title('HOST CPU Usage', size=16, fontweight="bold")
sns.lineplot(data=host_cpu_usage['_value'], ax=ax1)
ax1.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d %H:%M'))
ax1.set_xlabel('')
ax1.set_ylabel('(%)')
pos2 = ax1.get_position()
pos3 = [pos2.x0, pos2.y0 + 0.08, pos2.width, pos2.height]
ax1.set_position(pos3)
ax1.spines[['right', 'top']].set_visible(False)

## HOST Memory ##
ax2.set_title('HOST Memory Usage', size=16, fontweight="bold")
sns.lineplot(data=host_mem_usage['_value'], ax=ax2)
ax2.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d %H:%M'))
ax2.set_xlabel('')
ax2.set_ylabel('(GB)')
ax2.spines[['right', 'top']].set_visible(False)

## Container CPU Line Chart ##
ax3.set_title('Container CPU Usage', size=16, fontweight="bold")
sns.lineplot(data=container_cpu_usage[service_list], ax=ax3)
sns.move_legend(ax3, "upper left", bbox_to_anchor=(1, 1), title='Service Name')
ax3.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d %H:%M'))
ax3.set_ylabel('(%)')
ax3.set_xlabel('')
ax3.spines[['right', 'top']].set_visible(False)

## Container CPU Aggregation Table ##
ax4.set_title('Container CPU Aggregation', size=16, fontweight="bold")
container_cpu_agg_table = ax4.table(cellText=container_cpu_agg.values, cellLoc='right',
                                    colLabels=container_cpu_agg.columns,
                                    colColours=['lightblue'] * len(container_cpu_agg.columns),
                                    rowLoc='center', colLoc='center', loc='upper center')
container_cpu_agg_table.auto_set_font_size(False)
container_cpu_agg_table.set_fontsize(12)
container_cpu_agg_table.scale(1, 4)
ax4.axis('off')

## Container Memory Line Chart ##
ax5.set_title('Container Memory Usage', size=16, fontweight="bold")
sns.lineplot(data=container_mem_usage[service_list], ax=ax5)
sns.move_legend(ax5, "upper left", bbox_to_anchor=(1, 1), title='Service Name')
ax5.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d %H:%M'))
ax5.set_xlabel('')
ax5.set_ylabel('(MiB)')
ax5.spines[['right', 'top']].set_visible(False)

## Container Memory Aggregation Table ##
ax6.set_title('Container Memory Aggregation', size=16, fontweight="bold")
container_mem_agg_table = ax6.table(cellText=container_mem_agg.values, cellLoc='right',
                                    colLabels=container_mem_agg.columns,
                                    colColours=['lightblue'] * len(container_mem_agg.columns),
                                    rowLoc='center', colLoc='center', loc='upper center')
container_mem_agg_table.auto_set_font_size(False)
container_mem_agg_table.set_fontsize(12)
container_mem_agg_table.scale(1, 4)
ax6.axis('off')

fig.tight_layout(pad=0.4, w_pad=1.5, h_pad=10)

plt.setp(ax1.get_xticklabels(), rotation=30, horizontalalignment='right')
plt.setp(ax2.get_xticklabels(), rotation=30, horizontalalignment='right')
plt.setp(ax3.get_xticklabels(), rotation=30, horizontalalignment='right')
plt.setp(ax5.get_xticklabels(), rotation=30, horizontalalignment='right')

timestamp = int(time.time())
filename = "report-" + str(timestamp) + ".png"

plt.savefig(filename)
