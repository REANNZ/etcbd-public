#!/bin/bash

echo "Configuring elasticsearch NOT to create replicas..."
docker exec elasticsearch curl -Ss -HContent-Type:application/json -XPOST 'localhost:9200/_template/all' -d '{ "template": "*", "settings": { "number_of_replicas": 0 } }'

echo "Silencing JVM GC logs"
docker exec elasticsearch curl -Ss -HContent-Type:application/json -XPUT elasticsearch:9200/_clu'{ "persistent" : { "logger.org.elasticsearch.monitor.jvm.JvmGcMonitorService" : "WARN" } }'

echo "Loading dashboards and visualizations..."
docker exec kibana /load_dashboards.sh
echo "...done"

